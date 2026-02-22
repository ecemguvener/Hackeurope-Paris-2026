# frozen_string_literal: true

module Api
  module V1
    class TransformationsController < BaseController
      def create
        text = params[:text].to_s.strip
        style = params[:style] || "simplified"

        if text.blank?
          return render json: { error: "Text is required" }, status: :unprocessable_entity
        end

        result = TransformService.call(text, style: style, user_profile: current_user.profile)
        render json: result
      end
    end
  end
end
