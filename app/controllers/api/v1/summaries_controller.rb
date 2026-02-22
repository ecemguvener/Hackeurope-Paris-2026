# frozen_string_literal: true

module Api
  module V1
    class SummariesController < BaseController
      def create
        text = params[:text].to_s.strip

        if text.blank?
          return render json: { error: "Text is required" }, status: :unprocessable_entity
        end

        result = SummarizeService.call(text)
        render json: result
      end
    end
  end
end
