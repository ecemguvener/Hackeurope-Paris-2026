# frozen_string_literal: true

module Api
  module V1
    class TTSController < BaseController
      def create
        text = params[:text].to_s.strip
        voice = params[:voice] || TTSService::DEFAULT_VOICE
        speed = (params[:speed] || 1.0).to_f

        if text.blank?
          return render json: { error: "Text is required" }, status: :unprocessable_entity
        end

        result = TTSService.speak(text, voice: voice, speed: speed)
        render json: { audio_url: result.audio_url }
      rescue => e
        Rails.logger.error("TTS API error: #{e.message}")
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
