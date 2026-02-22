# frozen_string_literal: true

require "net/http"
require "uri"
require "ipaddr"
require "socket"
require "json"

# Agentic Claude service that analyses a web page, simplifies complex sections,
# and returns an accessible version.
#
# Usage:
#   result = WebReaderAgent.call(url: "https://example.com", page_text: "...", style: "simplified")
#   result[:accessible_content]  # => String
#   result[:tools_used]          # => Array<String>
#   result[:token_count]         # => Integer
class WebReaderAgent
  MODEL          = "claude-sonnet-4-6"
  MAX_ITERATIONS = 5
  MAX_INPUT_CHARS = 20_000
  MAX_TOKENS     = 4096

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an accessibility assistant that transforms web page content into clear, readable text.

    Your workflow for EVERY request:
    1. Call check_readability on the main body text to assess complexity.
    2. If any sections are rated "moderate" or "complex", call simplify_section on those sections.
    3. Optionally call fetch_linked_page at most once, only if a linked page is essential context.
    4. Return the COMPLETE accessible document — no meta-commentary, no preamble, just the transformed content.

    Rules:
    - Preserve all factual information; never invent content.
    - The output must be a single cohesive document, not a list of processed fragments.
    - Honour the requested style in every simplify_section call.
  PROMPT

  TOOLS = [
    {
      name: "check_readability",
      description: "Analyses text and returns readability metrics: word count, average words per sentence, percentage of long words (>6 chars), and overall level (easy/moderate/complex).",
      input_schema: {
        type: "object",
        properties: {
          text: { type: "string", description: "The text to analyse." }
        },
        required: ["text"]
      }
    },
    {
      name: "simplify_section",
      description: "Rewrites a section of text in the requested accessibility style.",
      input_schema: {
        type: "object",
        properties: {
          text:  { type: "string", description: "The section text to simplify." },
          style: {
            type: "string",
            description: "One of: simplified, bullet_points, plain_language, restructured.",
            enum: %w[simplified bullet_points plain_language restructured]
          }
        },
        required: ["text", "style"]
      }
    },
    {
      name: "fetch_linked_page",
      description: "Fetches a URL and returns the first 8 000 characters of its visible text. Only use for public http/https URLs when essential context is missing.",
      input_schema: {
        type: "object",
        properties: {
          url: { type: "string", description: "A public http or https URL to fetch." }
        },
        required: ["url"]
      }
    }
  ].freeze

  def self.call(url:, page_text:, style: "simplified")
    new(url: url, page_text: page_text, style: style).call
  end

  def initialize(url:, page_text:, style:)
    @url       = url
    @page_text = page_text.to_s.slice(0, MAX_INPUT_CHARS)
    @style     = style.presence_in(%w[simplified bullet_points plain_language restructured]) || "simplified"
    @tools_used = []
    @input_tokens  = 0
    @output_tokens = 0
  end

  def call
    client   = Anthropic::Client.new
    messages = initial_messages

    MAX_ITERATIONS.times do
      response = client.messages(
        model:      MODEL,
        system:     SYSTEM_PROMPT,
        tools:      TOOLS,
        messages:   messages,
        max_tokens: MAX_TOKENS
      )

      @input_tokens  += response.dig("usage", "input_tokens").to_i
      @output_tokens += response.dig("usage", "output_tokens").to_i

      messages << { role: "assistant", content: response["content"] }

      break if response["stop_reason"] == "end_turn"

      tool_results = process_tool_uses(response["content"])
      break if tool_results.empty?

      messages << { role: "user", content: tool_results }
    end

    final_text = extract_final_text(messages.last)

    {
      accessible_content: final_text,
      tools_used:         @tools_used.uniq,
      style:              @style,
      url:                @url,
      token_count:        @input_tokens + @output_tokens
    }
  end

  private

  def initial_messages
    [
      {
        role: "user",
        content: <<~MSG
          Please make the following web page accessible.

          URL: #{@url}
          Requested style: #{@style}

          PAGE CONTENT:
          #{@page_text}
        MSG
      }
    ]
  end

  def process_tool_uses(content_blocks)
    Array(content_blocks).filter_map do |block|
      next unless block["type"] == "tool_use"

      tool_name  = block["name"]
      tool_input = block["input"] || {}
      @tools_used << tool_name

      result = execute_tool(tool_name, tool_input)

      {
        type:        "tool_result",
        tool_use_id: block["id"],
        content:     result.to_s
      }
    end
  end

  def execute_tool(name, input)
    case name
    when "check_readability"   then check_readability(input["text"].to_s)
    when "simplify_section"    then simplify_section(input["text"].to_s, input["style"].to_s)
    when "fetch_linked_page"   then fetch_linked_page(input["url"].to_s)
    else                            "Unknown tool: #{name}"
    end
  rescue => e
    "Tool error (#{name}): #{e.message}"
  end

  # ── Tool implementations ───────────────────────────────────────────────────

  def check_readability(text)
    return { error: "Empty text" }.to_json if text.blank?

    words     = text.split
    sentences = text.split(/[.!?]+/).map(&:strip).reject(&:empty?)
    long_words = words.count { |w| w.gsub(/[^a-zA-Z]/, "").length > 6 }

    avg_sentence = sentences.empty? ? 0 : (words.length.to_f / sentences.length).round(1)
    long_word_pct = words.empty? ? 0 : ((long_words.to_f / words.length) * 100).round(1)

    level = if avg_sentence <= 15 && long_word_pct < 20
      "easy"
    elsif avg_sentence <= 25 && long_word_pct < 35
      "moderate"
    else
      "complex"
    end

    {
      word_count:             words.length,
      avg_words_per_sentence: avg_sentence,
      long_word_pct:          long_word_pct,
      level:                  level
    }.to_json
  end

  def simplify_section(text, style)
    return "" if text.blank?

    cleaned = TextCleaner.clean(text)

    case style
    when "bullet_points"
      sentences = cleaned.split(/(?<=[.!?])\s+/).map(&:strip).reject(&:empty?)
      sentences.map { |s| "- #{s}" }.join("\n")
    when "restructured"
      formatted = DyslexiaFormatter.format(cleaned)
      formatted.gsub(/\n\n(?!---)/, "\n\n---\n\n")
    else
      # simplified / plain_language — both use DyslexiaFormatter
      DyslexiaFormatter.format(cleaned)
    end
  end

  def fetch_linked_page(url)
    uri = begin
      URI.parse(url)
    rescue URI::InvalidURIError
      return "Error: Invalid URL"
    end

    unless %w[http https].include?(uri.scheme)
      return "Error: Only http/https URLs are allowed"
    end

    host = uri.host.to_s
    return "Error: Missing host" if host.blank?

    # SSRF guard — resolve and reject private / loopback addresses
    begin
      addrs = Addrinfo.getaddrinfo(host, nil, :UNSPEC, :STREAM)
      addrs.each do |addr|
        ip = IPAddr.new(addr.ip_address)
        if ip.loopback? || ip.private? || ip.link_local?
          return "Error: Fetching private/internal addresses is not allowed"
        end
      end
    rescue SocketError => e
      return "Error: Could not resolve host — #{e.message}"
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Qlarity-WebReader/1.0"

    response = http.request(request)

    raw = response.body.to_s.encode("UTF-8", invalid: :replace, undef: :replace)

    # Strip HTML tags simply (no extra gems)
    text = raw.gsub(/<script[^>]*>.*?<\/script>/mi, "")
              .gsub(/<style[^>]*>.*?<\/style>/mi, "")
              .gsub(/<[^>]+>/, " ")
              .gsub(/&amp;/, "&")
              .gsub(/&lt;/, "<")
              .gsub(/&gt;/, ">")
              .gsub(/&nbsp;/, " ")
              .gsub(/&#?\w+;/, "")
              .gsub(/\s{2,}/, " ")
              .strip

    TextCleaner.clean(text).slice(0, 8_000)
  rescue => e
    "Error fetching page: #{e.message}"
  end

  def extract_final_text(last_message)
    content = last_message.is_a?(Hash) ? last_message[:content] || last_message["content"] : nil
    return "" unless content

    Array(content)
      .select { |b| b.is_a?(Hash) && b["type"] == "text" }
      .map { |b| b["text"].to_s }
      .join("\n\n")
      .strip
  end
end
