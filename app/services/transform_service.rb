# frozen_string_literal: true

# Transforms text into dyslexia-friendly styles using Claude AI.
# Falls back to DyslexiaFormatter on API failure.
#
#   result = TransformService.call("Some complex text", style: "simplified")
#   result[:text]  # transformed text
#   result[:style] # style used
class TransformService
  STYLES = {
    "simplified" => {
      title: "Simplified",
      prompt: <<~PROMPT
        Rewrite the following text using shorter sentences and simpler vocabulary.
        Break long paragraphs into smaller chunks. Keep the meaning exactly the same.
        Use clear, direct language. Aim for a 6th-grade reading level.
        Return ONLY the rewritten text, no commentary.
      PROMPT
    },
    "bullet_points" => {
      title: "Bullet Points",
      prompt: <<~PROMPT
        Convert the following text into a well-organized bullet point format.
        Extract key information and present it as scannable bullet points.
        Group related points under short headings where appropriate.
        Keep the meaning exactly the same. Return ONLY the bullet points, no commentary.
      PROMPT
    },
    "plain_language" => {
      title: "Plain Language",
      prompt: <<~PROMPT
        Rewrite the following text replacing all jargon, technical terms, and complex
        vocabulary with everyday words. Keep the meaning exactly the same.
        If a technical term must stay, add a brief parenthetical explanation.
        Return ONLY the rewritten text, no commentary.
      PROMPT
    },
    "restructured" => {
      title: "Restructured",
      prompt: <<~PROMPT
        Reorganize the following text for easier reading flow. Put the most important
        information first. Use clear headings and short paragraphs. Add transition
        words between sections. Keep the meaning exactly the same.
        Return ONLY the restructured text, no commentary.
      PROMPT
    }
  }.freeze

  def self.call(text, style: "simplified", user_profile: {})
    new(text, style: style, user_profile: user_profile).call
  end

  def initialize(text, style: "simplified", user_profile: {})
    @text = TextCleaner.clean(text.to_s)
    @style = STYLES.key?(style) ? style : "simplified"
    @user_profile = user_profile
  end

  def call
    transformed = claude_transform
    { text: transformed, style: @style }
  rescue => e
    Rails.logger.error("TransformService Claude error: #{e.message}")
    { text: DyslexiaFormatter.format(@text), style: @style, fallback: true }
  end

  private

  def claude_transform
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    system_prompt = "You are a text accessibility specialist. You transform text to be easier to read for people with dyslexia and other reading difficulties."

    if @user_profile.present?
      prefs = @user_profile.map { |k, v| "- #{k}: #{v}" }.join("\n")
      system_prompt += "\n\nUser preferences:\n#{prefs}"
    end

    message = client.messages.create(
      model: "claude-sonnet-4-6",
      max_tokens: 4096,
      system: system_prompt,
      messages: [
        {
          role: "user",
          content: "#{STYLES[@style][:prompt]}\n\n---\n\n#{@text}"
        }
      ]
    )

    message.content.first.text.strip
  end
end
