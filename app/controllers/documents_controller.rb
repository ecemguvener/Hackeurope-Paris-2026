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

    @document.file.attach(uploaded_file)
    raw, extracted = extract_text(uploaded_file)
    @document.original_content = raw || uploaded_file.original_filename
    @document.extracted_text = extracted || @document.original_content
    @document.content_hash = Digest::SHA256.hexdigest(@document.original_content)

    if @document.save
      redirect_to results_path(@document)
    else
      flash.now[:alert] = "Something went wrong. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  def results
    @document = current_user.documents.find(params[:id])
  end

  def select_version
    @document = current_user.documents.find(params[:id])
    version = params[:version].to_i

    unless version.between?(1, Document::TRANSFORMATION_STYLES.length)
      redirect_to results_path(@document), alert: "Invalid version selection."
      return
    end

    @document.update!(selected_version: version)

    style = @document.selected_style
    current_user.update!(preferred_style: style[:title]) if style

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

    result = TTSService.speak(text, voice: voice)
    @document.update!(audio_url: result.audio_url)
    redirect_to collapsed_show_path(@document), notice: "Speech generated successfully."
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
end
