# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token!

      private

      def authenticate_token!
        token = request.headers["Authorization"]&.remove("Bearer ")
        @current_user = User.find_by(api_token: token) if token.present?

        unless @current_user
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end
    end
  end
end
