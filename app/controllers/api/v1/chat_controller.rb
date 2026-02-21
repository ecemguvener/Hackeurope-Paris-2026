# frozen_string_literal: true

module Api
  module V1
    class ChatController < BaseController
      def create
        message = params[:message].to_s.strip
        page_content = params[:page_content].to_s
        history = params[:history] || []

        if message.blank?
          return render json: { error: "Message is required" }, status: :unprocessable_entity
        end

        result = ChatService.call(
          message: message,
          page_content: page_content,
          history: history
        )
        render json: result
      end
    end
  end
end
