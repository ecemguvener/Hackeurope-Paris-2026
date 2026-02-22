# frozen_string_literal: true

module Api
  class WebReaderController < ActionController::API
    before_action :authenticate_api_token!

    # POST /api/web_reader
    def create
      url       = params[:url].presence
      page_text = params[:page_text].presence
      style     = params[:style].presence || "simplified"

      unless url && page_text
        return render json: { error: "url and page_text are required" }, status: :unprocessable_entity
      end

      quota = BillingService.check_quota(BillingService.company_id)
      unless quota.allowed
        return render json: { error: quota.reason }, status: :payment_required
      end

      result = WebReaderAgent.call(url: url, page_text: page_text, style: style)

      BillingService.record_usage(
        BillingService.company_id,
        characters: result[:accessible_content].length
      )

      render json: {
        accessible_content: result[:accessible_content],
        tools_used:         result[:tools_used],
        style:              result[:style],
        url:                result[:url],
        token_count:        result[:token_count]
      }
    rescue => e
      Rails.logger.error("[WebReaderController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      render json: { error: "Internal server error" }, status: :internal_server_error
    end

    private

    def authenticate_api_token!
      token = bearer_token
      unless token
        return render json: { error: "Missing Authorization header" }, status: :unauthorized
      end

      @api_user = User.find_by(api_token: token)
      unless @api_user
        render json: { error: "Invalid API token" }, status: :unauthorized
      end
    end

    def bearer_token
      header = request.headers["Authorization"].to_s
      header.start_with?("Bearer ") ? header.delete_prefix("Bearer ").strip : nil
    end
  end
end
