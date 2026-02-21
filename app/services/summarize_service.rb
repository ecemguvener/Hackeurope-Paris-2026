# frozen_string_literal: true

# Summarizes text into 3-5 bullet points using Claude AI.
#
#   result = SummarizeService.call("Long article text...")
#   result[:summary] # bullet point summary
class SummarizeService
  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = TextCleaner.clean(text.to_s)
  end

  def call
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    message = client.messages.create(
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      system: "You are a text summarization specialist focused on accessibility. Create clear, concise summaries.",
      messages: [
        {
          role: "user",
          content: <<~PROMPT
            Summarize the following text into 3-5 bullet points.
            Each bullet should capture a key idea in simple, clear language.
            Use short sentences. Return ONLY the bullet points, no commentary.

            ---

            #{@text}
          PROMPT
        }
      ]
    )

    { summary: message.content.first.text.strip }
  rescue => e
    Rails.logger.error("SummarizeService error: #{e.message}")
    { summary: "Unable to generate summary. Please try again.", error: true }
  end
end
