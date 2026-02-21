class DocumentsController < ApplicationController
  ALLOWED_CONTENT_TYPES = %w[
    text/plain
    application/pdf
    image/png
    image/jpeg
  ].freeze

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

    @document.file.attach(uploaded_file)
    @document.extracted_text = extract_text(uploaded_file)
    @document.original_content = @document.extracted_text || uploaded_file.original_filename
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

  def collapsed
    @document = current_user.documents.find(params[:id])
  end

  private

  def extract_text(uploaded_file)
    case uploaded_file.content_type
    when "text/plain"
      uploaded_file.rewind
      uploaded_file.read
    else
      # PDF and image text extraction deferred to AI agent integration
      nil
    end
  end
end
