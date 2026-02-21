# frozen_string_literal: true

require "base64"
require "pdf-reader"
require "mini_magick"
require "tempfile"

# Extracts text from images and PDFs.
#
#   result = TextExtractor.call("path/to/file.pdf")
#   result.raw_text      # verbatim extracted text
#   result.clean_text    # whitespace-normalised, hyphenation fixed
#   result.readable_text # dyslexia-friendly reformatting
#   result.method_used   # "image_vision" | "pdf_text_layer" | "pdf_vision"
#   result.per_page      # Array<{page:, text:}> for PDFs, nil for images
#
# Requires ANTHROPIC_API_KEY in the environment for vision extraction.
class TextExtractor
  VISION_EXTENSIONS = %w[.png .jpg .jpeg .webp].freeze
  PDF_EXTENSION = ".pdf"

  # Minimum characters from the text layer before we trust it
  # (short results usually mean a scanned / image-only PDF).
  MIN_TEXT_LAYER_LENGTH = 100

  VISION_PROMPT = <<~PROMPT.strip
    Extract all visible text from this image exactly as it appears.
    Output plain text only — no commentary, no explanations.
    Preserve paragraphs, headings, and lists.
    If any text is unclear or illegible, write [unclear] in its place.
    Do not invent or guess text that is not visible.
  PROMPT

  Result = Data.define(:raw_text, :clean_text, :readable_text, :method_used, :per_page,
                       :speech_enabled, :audio_url, :alignment)

  # speech_enabled: true calls TTSService and includes audio_url in the result.
  # voice / speed are forwarded to TTSService when speech is enabled.
  def self.call(file_path, speech_enabled: false, voice: TTSService::DEFAULT_VOICE, speed: 1.0)
    new(file_path, speech_enabled: speech_enabled, voice: voice, speed: speed).call
  end

  def initialize(file_path, speech_enabled: false, voice: TTSService::DEFAULT_VOICE, speed: 1.0)
    @file_path      = file_path.to_s
    @extension      = File.extname(@file_path).downcase
    @speech_enabled = speech_enabled
    @voice          = voice
    @speed          = speed
  end

  def call
    raw_text, method_used, per_page = extract
    clean_text    = TextCleaner.clean(raw_text)
    readable_text = DyslexiaFormatter.format(clean_text)

    audio_url = nil
    if @speech_enabled
      tts_result = TTSService.speak(readable_text, voice: @voice, speed: @speed)
      audio_url  = tts_result.audio_url
    end

    Result.new(
      raw_text:       raw_text,
      clean_text:     clean_text,
      readable_text:  readable_text,
      method_used:    method_used,
      per_page:       per_page,
      speech_enabled: @speech_enabled,
      audio_url:      audio_url,
      alignment:      nil
    )
  end

  private

  def extract
    if VISION_EXTENSIONS.include?(@extension)
      [ vision_extract(@file_path), "image_vision", nil ]
    elsif @extension == PDF_EXTENSION
      extract_pdf
    else
      raise ArgumentError, "Unsupported file type: #{@extension}"
    end
  end

  # -- PDF extraction --------------------------------------------------------

  def extract_pdf
    pages = text_layer_pages
    total = pages.sum { |p| p[:text].length }

    if pages.any? && total >= MIN_TEXT_LAYER_LENGTH
      return [ combine(pages), "pdf_text_layer", pages ]
    end

    pages = vision_pages
    [ combine(pages), "pdf_vision", pages ]
  end

  def combine(pages)
    pages.map { |p| "--- Page #{p[:page]} ---\n#{p[:text]}" }.join("\n\n")
  end

  def text_layer_pages
    reader = PDF::Reader.new(@file_path)
    reader.pages.map.with_index(1) { |page, i| { page: i, text: page.text.strip } }
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError
    []
  end

  def vision_pages
    page_paths = []
    page_paths = render_pdf_to_images
    page_paths.map.with_index(1) { |path, i| { page: i, text: vision_extract(path) } }
  ensure
    page_paths.each { |p| File.delete(p) if File.exist?(p) }
  end

  # Render each PDF page to a PNG temp file using ImageMagick (via MiniMagick).
  # Requires Ghostscript to be installed for PDF rendering.
  def render_pdf_to_images
    page_count = PDF::Reader.new(@file_path).page_count

    (0...page_count).map do |i|
      tmp = Tempfile.new([ "pdf_page_#{i}", ".png" ])
      tmp.close

      MiniMagick::Tool::Convert.new do |convert|
        convert.density(150)
        convert << "#{@file_path}[#{i}]"
        convert.background("white")
        convert.flatten
        convert << tmp.path
      end

      tmp.path
    end
  end

  # -- Vision extraction -----------------------------------------------------

  def vision_extract(image_path)
    encoded = Base64.strict_encode64(File.binread(image_path))

    message = anthropic_client.messages.create(
      model: "claude-sonnet-4-6",
      max_tokens: 4096,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: media_type_for(image_path),
                data: encoded
              }
            },
            { type: "text", text: VISION_PROMPT }
          ]
        }
      ]
    )

    message.content.first.text.strip
  end

  def anthropic_client
    @anthropic_client ||= Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
  end

  def media_type_for(path)
    case File.extname(path).downcase
    when ".png"        then "image/png"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".webp"       then "image/webp"
    else "image/png"
    end
  end
end
