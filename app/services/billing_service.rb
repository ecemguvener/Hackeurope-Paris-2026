# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# Billing client backed by the paid_ruby SDK.
# Handles quota checks, usage recording, and billing dashboard data.
#
# Runs in **stub mode** when PAID_API_KEY is unset — all requests are allowed
# and usage is only logged to Rails logger.
#
# Fails open by default (PAID_FAIL_OPEN=true): if the Paid API is unreachable,
# requests proceed rather than blocking users.
#
#   BillingService.check_quota(user, "text_extraction")
#   BillingService.record_usage(user, [{ event_name: "text_extraction", ... }])
#   BillingService.usage_summary(user)
#
class BillingService
  CACHE_TTL = 60 # seconds
  CREDIT_BUNDLES_BASE_URL = "https://api.agentpaid.io/api/v1"

  class QuotaExceeded < StandardError; end

  # ── Configuration ────────────────────────────────────────────
  class << self
    def api_key
      ENV["PAID_API_KEY"].presence
    end

    def fail_open?
      ENV.fetch("PAID_FAIL_OPEN", "true") == "true"
    end

    def stub_mode?
      api_key.blank?
    end

    # ── Public API ───────────────────────────────────────────

    # Check whether user has remaining quota for the given action.
    # Returns { allowed: true/false, remaining: N, customer: {...} }
    # Raises QuotaExceeded if not allowed and fail_open is false.
    def check_quota(user, action_type)
      if stub_mode?
        Rails.logger.info("[BillingService STUB] check_quota user=#{user.id} action=#{action_type} → allowed")
        return { allowed: true, remaining: nil, stub: true }
      end

      customer = fetch_customer(user)
      unless customer
        return fail_open_or_raise!("Customer not found in Paid.ai for user #{user.id}")
      end

      bundles = fetch_credit_bundles(user)
      remaining = calculate_remaining(bundles)

      if remaining <= 0
        if fail_open?
          Rails.logger.warn("[BillingService] Quota exceeded for user #{user.id}, but fail-open is enabled")
          return { allowed: true, remaining: 0, fail_open: true }
        else
          raise QuotaExceeded, "You've used all your credits. Please upgrade your plan."
        end
      end

      { allowed: true, remaining: remaining, customer: customer }
    rescue QuotaExceeded
      raise
    rescue => e
      fail_open_or_raise!(e.message)
    end

    # Record usage events to Paid.ai.
    # signals: Array of { event_name:, data: {} } hashes.
    # Non-fatal: errors are logged but never block the user.
    def record_usage(user, signals)
      external_id = external_customer_id(user)

      if stub_mode?
        signals.each do |s|
          Rails.logger.info("[BillingService STUB] record_usage user=#{user.id} event=#{s[:event_name]} data=#{s[:data]}")
        end
        return { recorded: signals.size, stub: true }
      end

      payload = signals.map do |signal|
        {
          event_name: signal[:event_name],
          customer_external_id: external_id,
          data: signal[:data] || {}
        }
      end

      response = client.usage.record_bulk(signals: payload)
      { recorded: signals.size, response: response }
    rescue => e
      Rails.logger.error("[BillingService] record_usage failed: #{e.message}")
      { recorded: 0, error: e.message }
    end

    # Fetch billing summary for the dashboard.
    # Returns { customer:, bundles:, remaining:, plan:, stub: }
    def usage_summary(user)
      if stub_mode?
        return {
          stub: true,
          customer: { name: user.name, external_id: external_customer_id(user) },
          bundles: [],
          remaining: nil,
          plan: "Stub Mode (no Paid.ai configured)"
        }
      end

      customer = fetch_customer(user)
      bundles = fetch_credit_bundles(user)
      remaining = calculate_remaining(bundles)

      plan_name = customer&.dig("orders")&.first&.dig("name") ||
                  customer&.dig("metadata", "plan") ||
                  "Free Tier"

      {
        customer: customer,
        bundles: bundles,
        remaining: remaining,
        plan: plan_name,
        stub: false
      }
    rescue => e
      Rails.logger.error("[BillingService] usage_summary failed: #{e.message}")
      {
        customer: { name: user.name, external_id: external_customer_id(user) },
        bundles: [],
        remaining: nil,
        plan: "Unknown (API error)",
        error: e.message,
        stub: false
      }
    end

    private

    # ── SDK client ─────────────────────────────────────────────

    def client
      @client ||= Paid::Client.new(token: api_key)
    end

    def external_customer_id(user)
      "qlarity_user_#{user.id}"
    end

    # ── API requests ──────────────────────────────────────────

    def fetch_customer(user)
      cache_key = "billing:customer:#{user.id}"
      cached = Rails.cache.read(cache_key)
      return cached if cached

      result = client.customers.get_by_external_id(external_id: external_customer_id(user))
      result = JSON.parse(result.to_json) if result.respond_to?(:to_json) && !result.is_a?(Hash)
      Rails.cache.write(cache_key, result, expires_in: CACHE_TTL.seconds) if result
      result
    rescue => e
      return nil if e.message.to_s.include?("404") || e.message.to_s.include?("not found")
      raise
    end

    # SDK doesn't expose credit bundles yet — use lightweight HTTP fallback.
    def fetch_credit_bundles(user)
      cache_key = "billing:bundles:#{user.id}"
      cached = Rails.cache.read(cache_key)
      return cached if cached

      uri = URI("#{CREDIT_BUNDLES_BASE_URL}/credit-bundles")
      uri.query = URI.encode_www_form(customer_external_id: external_customer_id(user))

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Accept"] = "application/json"

      response = http.request(request)

      case response.code.to_i
      when 200..299
        result = JSON.parse(response.body)
        bundles = result.is_a?(Array) ? result : (result.dig("data") || [])
        Rails.cache.write(cache_key, bundles, expires_in: CACHE_TTL.seconds)
        bundles
      when 404
        []
      else
        raise "Paid.ai credit-bundles API error (HTTP #{response.code}): #{response.body.to_s.truncate(200)}"
      end
    end

    def calculate_remaining(bundles)
      return 0 if bundles.blank?

      bundles.sum do |bundle|
        granted = bundle.dig("granted_amount") || bundle.dig("total") || 0
        used = bundle.dig("used_amount") || bundle.dig("used") || 0
        [ granted - used, 0 ].max
      end
    end

    def fail_open_or_raise!(message)
      if fail_open?
        Rails.logger.warn("[BillingService] #{message} — proceeding (fail-open)")
        { allowed: true, remaining: nil, fail_open: true }
      else
        raise QuotaExceeded, message
      end
    end
  end
end
