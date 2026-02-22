#!/usr/bin/env ruby
# frozen_string_literal: true

# ─── Bootstrap ────────────────────────────────────────────────────────────────
require "bundler/setup"
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "anthropic"
require "net/http"
require "json"
require "time"

# ─── Build OTLP auth headers from LANGSMITH_* env vars ────────────────────────
# Only sets the variable if the caller hasn't already set it directly.
# The key value is never printed anywhere in this script.
unless ENV["OTEL_EXPORTER_OTLP_HEADERS"]
  api_key = ENV.fetch("LANGSMITH_API_KEY") { abort "ERROR: LANGSMITH_API_KEY is not set." }
  project = ENV.fetch("LANGSMITH_PROJECT") { abort "ERROR: LANGSMITH_PROJECT is not set." }
  ENV["OTEL_EXPORTER_OTLP_HEADERS"] = "x-api-key=#{api_key},langsmith-project=#{project}"
end

abort "ERROR: OTEL_EXPORTER_OTLP_ENDPOINT is not set." unless ENV["OTEL_EXPORTER_OTLP_ENDPOINT"]
abort "ERROR: ANTHROPIC_API_KEY is not set."            unless ENV["ANTHROPIC_API_KEY"]

# ─── OpenTelemetry setup ──────────────────────────────────────────────────────
# The SDK reads OTEL_EXPORTER_OTLP_ENDPOINT and OTEL_EXPORTER_OTLP_HEADERS
# automatically from the environment — no need to pass them as arguments.
OpenTelemetry::SDK.configure do |c|
  c.service_name = "hackeurope-agent"
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new
    )
  )
end

TRACER = OpenTelemetry.tracer_provider.tracer("hackeurope-agent", "1.0.0")

# ─── Cost table (USD per token, as of Feb 2026) ───────────────────────────────
COST_PER_TOKEN = {
  "claude-3-haiku-20240307"    => { input: 0.25  / 1_000_000.0, output: 1.25  / 1_000_000.0 },
  "claude-3-5-haiku-20241022"  => { input: 0.80  / 1_000_000.0, output: 4.00  / 1_000_000.0 },
  "claude-3-5-sonnet-20241022" => { input: 3.00  / 1_000_000.0, output: 15.00 / 1_000_000.0 },
  "claude-3-7-sonnet-20250219" => { input: 3.00  / 1_000_000.0, output: 15.00 / 1_000_000.0 },
}.freeze

MODEL = ENV.fetch("AGENT_MODEL", "claude-3-haiku-20240307")

# ─── Run summary accumulator ──────────────────────────────────────────────────
$summary = {
  started_at:              Time.now.iso8601,
  model:                   MODEL,
  steps:                   [],
  total_prompt_tokens:     0,
  total_completion_tokens: 0,
  total_tokens:            0,
  total_cost_usd:          0.0,
  total_retries:           0,
  errors:                  []
}

# ─── Retry with exponential backoff ───────────────────────────────────────────
#
# - Records every retry attempt as a span attribute ("retry.attempt").
# - Captures each exception on the span via record_exception.
# - After max_attempts, marks the span as ERROR and re-raises.
#
def with_retries(span:, op:, max_attempts: 3, base_delay: 0.5)
  attempt = 0
  begin
    attempt += 1
    span.set_attribute("retry.attempt", attempt) if attempt > 1
    yield
  rescue => e
    span.record_exception(e)
    $summary[:total_retries] += 1
    $summary[:errors] << {
      step:    op,
      attempt: attempt,
      class:   e.class.to_s,
      message: e.message
    }
    puts "  [retry] op=#{op} attempt=#{attempt}/#{max_attempts} #{e.class}: #{e.message}"
    if attempt < max_attempts
      delay = base_delay * (2**(attempt - 1))
      puts "  [backoff] sleeping #{delay.round(2)}s before attempt #{attempt + 1}"
      sleep delay
      retry
    else
      span.status = OpenTelemetry::Trace::Status.error("#{e.class}: #{e.message}")
      raise
    end
  end
end

# ─── Tool call: dummy HTTP GET (simulates fetching external data) ──────────────
def call_tool
  TRACER.in_span("tool.http_request", attributes: {
    "tool.name"  => "fetch_news_stub",
    "http.url"   => "https://httpbin.org/get"
  }) do |span|
    with_retries(span: span, op: "tool") do
      uri      = URI("https://httpbin.org/get?source=hackeurope-agent")
      response = Net::HTTP.get_response(uri)
      span.set_attribute("http.status_code", response.code.to_i)
      puts "  [tool] GET #{uri} → HTTP #{response.code}"
      JSON.parse(response.body)
    end
  end
end

# ─── LLM call with token accounting and cost estimation ───────────────────────
def call_llm(prompt, step_name)
  client = Anthropic::Client.new  # reads ANTHROPIC_API_KEY from env

  TRACER.in_span("llm.#{step_name}", attributes: {
    "llm.provider" => "anthropic",
    "llm.model"    => MODEL
  }) do |span|
    with_retries(span: span, op: "llm/#{step_name}") do
      msg = client.messages.create(
        model:      MODEL,
        max_tokens: 256,
        messages:   [{ role: "user", content: prompt }]
      )

      input  = msg.usage.input_tokens
      output = msg.usage.output_tokens
      total  = input + output
      rates  = COST_PER_TOKEN.fetch(MODEL, { input: 0.0, output: 0.0 })
      cost   = (input * rates[:input]) + (output * rates[:output])
      text   = msg.content.first.text

      # Span attributes the user asked for
      span.set_attribute("prompt_tokens",      input)
      span.set_attribute("completion_tokens",  output)
      span.set_attribute("total_tokens",       total)
      span.set_attribute("cost_usd_estimated", cost.round(8))

      # Accumulate into the run summary
      $summary[:total_prompt_tokens]     += input
      $summary[:total_completion_tokens] += output
      $summary[:total_tokens]            += total
      $summary[:total_cost_usd]          += cost

      puts "  [llm/#{step_name}] #{input}+#{output} tokens  $#{"%.6f" % cost}"
      text
    end
  end
end

# ─── Step 1: Plan ─────────────────────────────────────────────────────────────
def step_plan
  puts "\n[1/3] plan"
  TRACER.in_span("agent.plan", attributes: { "agent.step" => "plan" }) do |span|
    t0     = Time.now
    result = call_llm(
      "You are a planning agent. In 3 concise bullet points, outline a research plan " \
      "to summarise the latest AI news for a Paris hackathon briefing. Be brief.",
      "plan"
    )
    latency = (Time.now - t0).round(3)
    span.set_attribute("step.latency_s", latency)
    $summary[:steps] << { name: "plan", latency_s: latency }
    puts "  #{result[0..120].gsub("\n", " ")}..."
    result
  end
end

# ─── Step 2: Execute (includes tool call) ────────────────────────────────────
def step_execute(plan)
  puts "\n[2/3] execute"
  TRACER.in_span("agent.execute", attributes: { "agent.step" => "execute" }) do |span|
    t0        = Time.now
    tool_data = call_tool
    result    = call_llm(
      "Execute this research plan:\n#{plan[0..300]}\n\n" \
      "External data fetched by tool: #{tool_data.to_json[0..200]}\n\n" \
      "Write a 2-sentence hackathon briefing.",
      "execute"
    )
    latency = (Time.now - t0).round(3)
    span.set_attribute("step.latency_s", latency)
    $summary[:steps] << { name: "execute", latency_s: latency }
    puts "  #{result[0..120].gsub("\n", " ")}..."
    result
  end
end

# ─── Step 3: Verify ───────────────────────────────────────────────────────────
def step_verify(briefing)
  puts "\n[3/3] verify"
  TRACER.in_span("agent.verify", attributes: { "agent.step" => "verify" }) do |span|
    t0     = Time.now
    result = call_llm(
      "Review this briefing and respond with only PASS or FAIL followed by one reason sentence:\n\n#{briefing}",
      "verify"
    )
    latency = (Time.now - t0).round(3)
    passed  = result.strip.start_with?("PASS")
    span.set_attribute("step.latency_s", latency)
    span.set_attribute("verify.passed",  passed)
    $summary[:steps] << { name: "verify", latency_s: latency, passed: passed }
    puts "  verdict: #{result.strip[0..100]}"
    result
  end
end

# ─── Main ─────────────────────────────────────────────────────────────────────
puts "=== Hackeurope Agent ==="
puts "endpoint → #{ENV["OTEL_EXPORTER_OTLP_ENDPOINT"]}"
puts "project  → #{ENV["LANGSMITH_PROJECT"]}"
puts "model    → #{MODEL}"

t_start = Time.now

TRACER.in_span("agent.run", attributes: { "agent.version" => "1.0.0" }) do |_root|
  plan     = step_plan
  briefing = step_execute(plan)
  _verdict = step_verify(briefing)
end

total_latency = (Time.now - t_start).round(3)

$summary[:finished_at]     = Time.now.iso8601
$summary[:total_latency_s] = total_latency
$summary[:total_cost_usd]  = $summary[:total_cost_usd].round(8)

puts "\n=== Summary ==="
puts "  latency : #{total_latency}s"
puts "  tokens  : #{$summary[:total_tokens]}"
puts "  cost    : $#{"%.6f" % $summary[:total_cost_usd]}"
puts "  retries : #{$summary[:total_retries]}"
puts "  errors  : #{$summary[:errors].size}"

summary_path = File.join(__dir__, "runs_summary.json")
File.write(summary_path, JSON.pretty_generate($summary))
puts "\n  → #{summary_path}"

# Force-flush the async BatchSpanProcessor before the process exits
OpenTelemetry.tracer_provider.shutdown

puts "\nDone. View run: https://smith.langchain.com/o/~/projects/p/#{ENV["LANGSMITH_PROJECT"]}"
