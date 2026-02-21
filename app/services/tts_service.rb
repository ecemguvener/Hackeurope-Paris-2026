# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "fileutils"
require "securerandom"

# Converts text to natural-sounding speech via the ElevenLabs API.
#
#   result = TTSService.speak("Hello world", voice: "rachel", speed: 1.0)
#   result.audio_url   # "/audio/abc123def456.mp3" — playable URL
#   result.duration    # nil (not returned by basic endpoint)
#   result.alignment   # nil (optional; not requested by default)
#
# Requires ELEVENLABS_API_KEY in the environment.
# Audio is saved to public/audio/ and served statically.
class TTSService
  # Friendly name → ElevenLabs voice ID mapping.
  VOICES = {
    "rachel" => "21m00Tcm4TlvDq8ikWAM",
    "aria"   => "9BWtsMINqrJLrRacOk9x",
    "roger"  => "CwhRBWXzGAHq8TQ4Fs17",
    "sarah"  => "EXAVITQu4vr4xnSDxMaL",
    "george" => "JBFqnCBsd6RMkjVDRZzb"
  }.freeze

  DEFAULT_VOICE = "rachel"

  # eleven_turbo_v2_5 supports server-side speed parameter (0.7–1.2).
  MODEL_ID = "eleven_turbo_v2_5"

  API_BASE = "https://api.elevenlabs.io/v1/text-to-speech"

  # Characters per chunk — safe for free-tier (5 000 char limit).
  MAX_CHUNK_CHARS = 2_500

  Result = Data.define(:audio_url, :duration, :alignment)

  def self.speak(text, voice: DEFAULT_VOICE, speed: 1.0)
    new(text, voice: voice, speed: speed).speak
  end

  def initialize(text, voice: DEFAULT_VOICE, speed: 1.0)
    @text     = text.to_s.strip
    @voice_id = resolve_voice(voice)
    @speed    = speed.to_f.clamp(0.7, 1.2)
    @api_key  = ENV.fetch("ELEVENLABS_API_KEY") do
      raise KeyError, "ELEVENLABS_API_KEY is not set. Add it to your .env file."
    end
  end

  def speak
    chunks     = split_into_chunks(@text)
    audio_data = chunks.map { |chunk| generate_audio(chunk) }
    combined   = audio_data.reduce(:+)   # Concatenate MP3 binary streams
    audio_path = save_audio(combined)
    audio_url  = "/audio/#{File.basename(audio_path)}"

    Result.new(audio_url: audio_url, duration: nil, alignment: nil)
  end

  private

  def resolve_voice(voice)
    VOICES[voice.to_s.downcase] || VOICES[DEFAULT_VOICE]
  end

  # Splits text at sentence boundaries, keeping each chunk under MAX_CHUNK_CHARS.
  # Falls back to word-level splitting for sentences that are themselves too long.
  def split_into_chunks(text)
    return [ text ] if text.length <= MAX_CHUNK_CHARS

    chunks  = []
    current = +""

    sentences = text.scan(/[^.!?\n]+[.!?]*\n*/)

    sentences.each do |sentence|
      sentence = sentence.strip
      next if sentence.empty?

      if sentence.length > MAX_CHUNK_CHARS
        # Single sentence exceeds limit — split by words
        chunks << current.strip unless current.empty?
        current = +""
        words = sentence.split
        words.each do |word|
          if current.length + word.length + 1 > MAX_CHUNK_CHARS
            chunks << current.strip unless current.empty?
            current = word
          else
            current += (current.empty? ? "" : " ") + word
          end
        end
      elsif current.length + sentence.length + 1 > MAX_CHUNK_CHARS
        chunks << current.strip unless current.empty?
        current = sentence
      else
        current += (current.empty? ? "" : " ") + sentence
      end
    end

    chunks << current.strip unless current.empty?
    chunks.reject(&:empty?)
  end

  def generate_audio(text)
    uri              = URI("#{API_BASE}/#{@voice_id}")
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.open_timeout = 10
    http.read_timeout = 30

    request                  = Net::HTTP::Post.new(uri.path)
    request["xi-api-key"]   = @api_key
    request["Content-Type"] = "application/json"
    request["Accept"]       = "audio/mpeg"
    request.body = {
      text:           text,
      model_id:       MODEL_ID,
      voice_settings: {
        stability:        0.5,
        similarity_boost: 0.75,
        speed:            @speed
      }
    }.to_json

    response = with_retry { http.request(request) }
    handle_response!(response)
    response.body
  end

  def handle_response!(response)
    case response.code.to_i
    when 200 then nil
    when 401
      raise "Invalid ElevenLabs API key. Check ELEVENLABS_API_KEY in your .env file."
    when 422
      raise "ElevenLabs rejected the request. The text may contain unsupported characters."
    when 429
      raise "ElevenLabs API quota exceeded. Check your plan limits at elevenlabs.io."
    else
      raise "ElevenLabs API error (HTTP #{response.code}): #{response.body.to_s.slice(0, 200)}"
    end
  end

  def with_retry
    attempts = 0
    begin
      yield
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      attempts += 1
      retry if attempts == 1
      raise "TTS request timed out after retrying: #{e.message}"
    end
  end

  def save_audio(binary_data)
    dir = Rails.root.join("public", "audio")
    FileUtils.mkdir_p(dir)
    path = dir.join("#{SecureRandom.hex(12)}.mp3")
    File.binwrite(path, binary_data)
    path
  end
end
