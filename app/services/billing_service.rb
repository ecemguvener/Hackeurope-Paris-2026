# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# Handles quota enforcement and usage recording via the Paid.ai billing API.
#
# == Configuration (environment variables)
#
#   PAID_API_URL     Base URL for the Paid.ai API.
#                    Omit (or leave blank) to run in STUB mode — all requests
#                    are allowed and usage is only logged locally.
#                    Example: https://api.agentpaid.io/api/v1
#
#   PAID_API_KEY     Bearer token for Paid.ai API authentication.
#
#   PAID_COMPANY_ID  External customer ID in Paid.ai (default: "demo-company-1").
#                    Set this to the externalId of the customer you created in
#                    your Paid.ai dashboard.
#
#   PAID_FAIL_OPEN   If "true" (default), allow requests when billing is
#                    unreachable instead of blocking them. Set to "false" in
#                    production to enforce hard quota limits.
#
# == Usage
#
#   BillingService.check_quota(company_id)                              # QuotaResult
#   BillingService.record_usage(company_id, pages:, characters:, audio_minutes:)
#   BillingService.usage_summary(company_id)                            # Hash
#   BillingService.company_id                                           # String
#   BillingService.stub_mode?                                           # Bool
module BillingService
  PRODUCTION_URL = "https://api.agentpaid.io/api/v1"
  CACHE_TTL      = 60 # seconds

  # Returned by check_quota.
  #   allowed   — whether the request should proceed
  #   available — credits remaining (-1 means unlimited / no limits set)
  #   total     — total credits allocated (-1 means unlimited)
  #   used      — credits consumed so far
  #   plan      — descriptive plan label
  #   reason    — human-readable explanation when allowed is false (or nil)
  QuotaResult = Data.define(:allowed, :available, :total, :used, :plan, :reason)

  class << self
    # Returns a QuotaResult indicating whether the company may proceed.
    def check_quota(company_id)
      if stub_mode?
        log_stub("check_quota", "company=#{company_id} → allowed")
        return stub_quota
      end

      cached_quota(company_id)
    rescue => e
      handle_billing_error("check_quota", e)
    end

    # Records consumption signals to Paid.ai.
    # Non-fatal — logs on failure rather than raising.
    def record_usage(company_id, pages: 0, characters: 0, audio_minutes: 0.0)
      if stub_mode?
        log_stub("record_usage",
          "company=#{company_id} pages=#{pages} chars=#{characters} " \
          "audio_min=#{audio_minutes.round(3)}")
        return
      end

      signals = build_signals(company_id, pages, characters, audio_minutes)
      return if signals.empty?

      post_json("/usage/signals/bulk", { signals: signals })
    rescue => e
      # Usage recording is non-fatal — never block a user over it.
      Rails.logger.error("[BillingService] record_usage failed: #{e.message}")
    end

    # Returns a summary hash suitable for the admin billing view.
    def usage_summary(company_id)
      return stub_summary(company_id) if stub_mode?

      customer = get_customer_by_external_id(company_id)
      return stub_summary(company_id).merge(error: "Customer '#{company_id}' not found in Paid.ai") unless customer

      entitlements = get_entitlements(customer["id"]) || []
      build_summary(customer, entitlements)
    rescue => e
      Rails.logger.error("[BillingService] usage_summary failed: #{e.message}")
      stub_summary(company_id).merge(error: e.message)
    end

    # The external customer ID this app uses for all billing calls.
    def company_id
      ENV["PAID_COMPANY_ID"].presence || "demo-company-1"
    end

    # True when PAID_API_URL is not configured — run entirely in stub mode.
    def stub_mode?
      ENV["PAID_API_URL"].blank?
    end

    private

    # ── Quota ─────────────────────────────────────────────────────────────────

    def cached_quota(company_id)
      Rails.cache.fetch("billing:quota:#{company_id}", expires_in: CACHE_TTL.seconds) do
        fetch_quota(company_id)
      end
    end

    def fetch_quota(company_id)
      customer = get_customer_by_external_id(company_id)

      unless customer
        return QuotaResult.new(
          allowed:   fail_open?,
          available: 0, total: 0, used: 0,
          plan:      "unknown",
          reason:    "Customer '#{company_id}' not found in Paid.ai. " \
                     "Create the customer or set PAID_COMPANY_ID correctly."
        )
      end

      entitlements = get_entitlements(customer["id"]) || []

      if entitlements.empty?
        # Customer exists but has no entitlements — treat as unlimited.
        return QuotaResult.new(
          allowed: true, available: -1, total: -1, used: -1,
          plan:    "unlimited",
          reason:  nil
        )
      end

      total     = entitlements.sum { |e| e["total"].to_i }
      used      = entitlements.sum { |e| e["used"].to_i }
      available = entitlements.sum { |e| e["available"].to_i }
      allowed   = available > 0

      QuotaResult.new(
        allowed:   allowed,
        available: available,
        total:     total,
        used:      used,
        plan:      "active",
        reason:    allowed ? nil : "Quota exhausted (#{used}/#{total} credits used). " \
                                   "Please upgrade your plan."
      )
    end

    # ── Usage Signals ─────────────────────────────────────────────────────────

    def build_signals(company_id, pages, characters, audio_minutes)
      signals = []

      if pages > 0 || characters > 0
        signals << {
          event_name:           "text_extraction",
          external_customer_id: company_id,
          data: { pages: pages, characters: characters, app: "qlarity" }
        }
      end

      if audio_minutes.to_f > 0
        signals << {
          event_name:           "tts_generation",
          external_customer_id: company_id,
          data: { audio_minutes: audio_minutes.round(4), characters: characters, app: "qlarity" }
        }
      end

      signals
    end

    # ── Summary ───────────────────────────────────────────────────────────────

    def build_summary(customer, entitlements)
      total     = entitlements.sum { |e| e["total"].to_i }
      used      = entitlements.sum { |e| e["used"].to_i }
      available = entitlements.sum { |e| e["available"].to_i }

      {
        customer_name: customer["name"],
        external_id:   customer["externalId"] || customer["id"],
        plan:          entitlements.any? ? "active" : "no_plan",
        total:         total,
        used:          used,
        available:     available,
        entitlements:  entitlements,
        stub:          false,
        error:         nil
      }
    end

    def stub_summary(company_id)
      {
        customer_name: "Demo Company",
        external_id:   company_id,
        plan:          "stub",
        total:         -1,
        used:          0,
        available:     -1,
        entitlements:  [],
        stub:          true,
        error:         nil
      }
    end

    # ── HTTP helpers ──────────────────────────────────────────────────────────

    def get_customer_by_external_id(external_id)
      get_json("/customers/external/#{external_id}")
    end

    def get_entitlements(customer_id)
      result = get_json("/customers/#{customer_id}/credit-bundles")
      Array(result)
    end

    def get_json(path)
      uri  = URI("#{base_url}#{path}")
      http = build_http(uri)
      req  = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      req["Accept"]        = "application/json"

      resp = with_retry { http.request(req) }
      return nil if resp.code.to_i == 404

      handle_response!(resp)
      JSON.parse(resp.body)
    end

    def post_json(path, body)
      uri  = URI("#{base_url}#{path}")
      http = build_http(uri)
      req  = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      req["Content-Type"]  = "application/json"
      req["Accept"]        = "application/json"
      req.body             = body.to_json

      resp = with_retry { http.request(req) }
      handle_response!(resp)
      JSON.parse(resp.body) rescue nil
    end

    def build_http(uri)
      http              = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 10
      http
    end

    def handle_response!(resp)
      code = resp.code.to_i
      return if code >= 200 && code < 300

      body = JSON.parse(resp.body) rescue {}
      msg  = body.dig("error", "message") || body["message"] || resp.body.to_s.slice(0, 200)
      raise "Paid.ai API error (HTTP #{code}): #{msg}"
    end

    def with_retry
      attempts = 0
      begin
        yield
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
        attempts += 1
        retry if attempts == 1
        raise "Paid.ai unreachable after retry: #{e.message}"
      end
    end

    def base_url
      ENV["PAID_API_URL"].to_s.chomp("/")
    end

    def api_key
      ENV["PAID_API_KEY"].to_s
    end

    def fail_open?
      ENV.fetch("PAID_FAIL_OPEN", "true") == "true"
    end

    def handle_billing_error(context, error)
      Rails.logger.error("[BillingService] #{context} failed: #{error.message}")
      if fail_open?
        Rails.logger.warn("[BillingService] Failing open — request allowed despite billing error")
        QuotaResult.new(
          allowed:   true,
          available: -1, total: -1, used: -1,
          plan:      "unknown",
          reason:    "Billing check failed (fail-open): #{error.message}"
        )
      else
        QuotaResult.new(
          allowed:   false,
          available: 0, total: 0, used: 0,
          plan:      "unknown",
          reason:    "Billing service unavailable. Please try again later."
        )
      end
    end

    def log_stub(action, detail)
      Rails.logger.info("[BillingService STUB] #{action} #{detail} " \
                        "(set PAID_API_URL to enable real billing)")
    end
  end
end
