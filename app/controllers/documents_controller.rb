class DocumentsController < ApplicationController
  ALLOWED_CONTENT_TYPES = %w[
    text/plain
    application/pdf
    image/png
    image/jpeg
    image/webp
  ].freeze

  MAX_FILE_SIZE = 5.megabytes

  def new
    @document = Document.new
  end

  def create
    unless params.dig(:document, :file).present?
      @document = Document.new
      flash.now[:alert] = "Please select a file to upload"
      return render :new, status: :unprocessable_entity
    end

    @document = current_user.documents.build
    uploaded_file = params[:document][:file]

    unless ALLOWED_CONTENT_TYPES.include?(uploaded_file.content_type)
      flash.now[:alert] = "File type not supported. Please upload a .txt, .pdf, .png, or .jpg file."
      return render :new, status: :unprocessable_entity
    end

    if uploaded_file.size > MAX_FILE_SIZE
      flash.now[:alert] = "File is too large. Maximum size is 5MB."
      return render :new, status: :unprocessable_entity
    end

    # Billing: check quota before extraction
    quota = BillingService.check_quota(current_user, "text_extraction")
    unless quota[:allowed]
      flash.now[:alert] = "You've used all your credits. Please upgrade your plan."
      return render :new, status: :payment_required
    end

    @document.file.attach(uploaded_file)
    raw, extracted = extract_text(uploaded_file)
    @document.original_content = raw || uploaded_file.original_filename
    @document.extracted_text = extracted || @document.original_content
    @document.content_hash = Digest::SHA256.hexdigest(@document.original_content)

    if @document.save
      # Billing: record extraction usage
      page_count = uploaded_file.content_type == "application/pdf" ? (PDF::Reader.new(uploaded_file.tempfile.path).page_count rescue 1) : 1
      char_count = @document.extracted_text.to_s.length
      BillingService.record_usage(current_user, [
        {
          event_name: "text_extraction",
          data: { pages: page_count, characters: char_count, content_type: uploaded_file.content_type }
        }
      ])

      # Agent picks one style based on onboarding/profile/history, then generates only that style.
      recommended_style = SuperpositionRunner.recommend_style(@document, current_user)
      result = SuperpositionRunner.call(@document, current_user, styles: [ recommended_style ])
      transformations = {}
      result[:candidates].each do |candidate|
        transformations[candidate[:style]] = { "content" => candidate[:content] }
      end
      transformations["_meta"] = {
        "recommended_style" => result[:recommended_style],
        "decision_trace" => result[:decision_trace],
        "metrics" => result[:metrics]
      }
      @document.update!(transformations: transformations)

      CollapseRunner.call(@document, recommended_style, {})
      redirect_to collapsed_show_path(@document)
    else
      flash.now[:alert] = "Something went wrong. Please try again."
      render :new, status: :unprocessable_entity
    end
  rescue BillingService::QuotaExceeded => e
    @document = Document.new
    flash.now[:alert] = e.message
    render :new, status: :payment_required
  end

  def results
    @document = current_user.documents.find(params[:id])
  end

  def select_version
    @document = current_user.documents.find(params[:id])
    requested_version = params[:version].to_i
    style_key = style_key_from_version(requested_version)

    unless style_key
      redirect_to results_path(@document), alert: "Invalid version selection."
      return
    end

    signals = collapse_signals_from_params

    CollapseRunner.call(@document, style_key, signals)

    redirect_to collapsed_show_path(@document)
  end

  def collapsed
    @document = current_user.documents.find(params[:id])
    redirect_to results_path(@document) unless @document.version_selected?
  end

  def generate_speech
    @document = current_user.documents.find(params[:id])
    voice     = params[:voice].presence || TTSService::DEFAULT_VOICE
    text      = @document.selected_content.presence || @document.extracted_text

    unless text.present?
      redirect_to collapsed_show_path(@document), alert: "No text available to generate speech from."
      return
    end

    # Billing: check quota before TTS
    quota = BillingService.check_quota(current_user, "tts_generation")
    unless quota[:allowed]
      redirect_to collapsed_show_path(@document), alert: "You've used all your credits. Please upgrade your plan."
      return
    end

    result = TTSService.speak(text, voice: voice)
    @document.update!(audio_url: result.audio_url)

    # Billing: record TTS usage
    audio_minutes = (text.length / 1000.0 * 0.4).round(2) # rough estimate
    BillingService.record_usage(current_user, [
      {
        event_name: "tts_generation",
        data: { characters: text.length, audio_minutes: audio_minutes, voice: voice }
      }
    ])

    redirect_to collapsed_show_path(@document), notice: "Speech generated successfully."
  rescue BillingService::QuotaExceeded => e
    redirect_to collapsed_show_path(@document), alert: e.message
  rescue KeyError => e
    redirect_to collapsed_show_path(@document), alert: e.message
  rescue => e
    Rails.logger.error("TTSService failed: #{e.message}")
    redirect_to collapsed_show_path(@document), alert: "Speech generation failed: #{e.message}"
  end

  private

  # Returns [raw_text, clean_text] for non-plain-text files, or [text, text] for .txt.
  def extract_text(uploaded_file)
    if uploaded_file.content_type == "text/plain"
      uploaded_file.rewind
      text = uploaded_file.read
      return [ text, text ]
    end

    result = TextExtractor.call(uploaded_file.tempfile.path)
    [ result.raw_text, result.clean_text ]
  rescue => e
    Rails.logger.error("TextExtractor failed: #{e.message}")
    [ nil, nil ]
  end

  def style_key_from_version(version)
    return nil unless version.between?(1, Document::TRANSFORMATION_STYLES.length)

    Document::TRANSFORMATION_STYLES[version - 1][:key]
  end

  def collapse_signals_from_params
    {
      dwell_ms: params[:dwell_ms],
      tts_style: params[:tts_style]
    }.compact
  end
end
