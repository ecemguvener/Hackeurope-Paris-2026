# frozen_string_literal: true

# Q&A chat about page content using Claude AI with conversation history.
#
#   result = ChatService.call(
#     message: "What is this page about?",
#     page_content: "...",
#     history: [{ role: "user", content: "Hi" }, { role: "assistant", content: "Hello!" }]
#   )
#   result[:reply] # Claude's answer
class ChatService
  MAX_CONTEXT_CHARS = 12_000

  def self.call(message:, page_content: "", history: [])
    new(message: message, page_content: page_content, history: history).call
  end

  def initialize(message:, page_content: "", history: [])
    @message = message.to_s.strip
    @page_content = page_content.to_s.truncate(MAX_CONTEXT_CHARS)
    @history = Array(history).last(20) # Keep last 20 messages
  end

  def call
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    system = "You are Qlarity, a helpful AI assistant specialized in making web content accessible. " \
             "You help people with dyslexia and other reading difficulties understand web pages. " \
             "Answer questions clearly and concisely using simple language."

    if @page_content.present?
      system += "\n\nThe user is currently viewing a web page. Here is the page content:\n\n#{@page_content}"
    end

    messages = build_messages

    response = client.messages.create(
      model: "claude-sonnet-4-6",
      max_tokens: 2048,
      system: system,
      messages: messages
    )

    { reply: response.content.first.text.strip }
  rescue => e
    Rails.logger.error("ChatService error: #{e.message}")
    { reply: "Sorry, I couldn't process your message. Please try again.", error: true }
  end

  private

  def build_messages
    messages = @history.map do |msg|
      { role: msg["role"] || msg[:role], content: msg["content"] || msg[:content] }
    end
    messages << { role: "user", content: @message }
    messages
  end
end
