class SuperpositionRunner
  # The 4 writing styles with their instructions for Claude
  # %s is a placeholder where the actual document text gets inserted
  STYLES = {
    simplified:    "Rewrite the following with shorter sentences and clearer structure for someone with dyslexia:\n\n%s",
    bullet_points: "Rewrite the following as clear bullet points, scannable and short:\n\n%s",
    plain_language: "Rewrite the following replacing all jargon with simple everyday words:\n\n%s",
    restructured:  "Reorganize the following for easier reading flow with headers and sections:\n\n%s"
  }

  # Main function - Person 1 calls this after a document is uploaded
  # It receives the extracted text and the user, returns 4 rewritten versions
  def self.call(text, user = nil)

    # Step 1 (agentic part): decide which style to recommend automatically
    # The agent reads the user profile first, then analyses the text itself
    recommended = detect_best_style(text, user)

    # Step 2: loop through all 4 styles and ask Claude to rewrite the text each way
    # versions{} starts as an empty hash and gets filled with 4 results
    versions = {}
    STYLES.each do |style, prompt_template|
      # Insert the actual text into the prompt where %s is
      prompt = prompt_template % text
      # Send to Claude and save the result under the style name
      versions[style] = call_llm(prompt)
    end

    # Step 3: return everything - all 4 versions + which one we recommend
    { versions: versions, recommended_style: recommended }
  end

  private

  # Agentic decision: looks at user profile first, then falls back to text analysis
  # This means the agent personalises the recommendation to the person, not just the text
  def self.detect_best_style(text, user)
    # Check user profile first (set during onboarding reading test)
    if user&.profile.present?
      return :bullet_points  if user.profile["has_dyslexia_pattern"] == true
      return :plain_language if user.profile["main_struggle"] == "vocabulary"
      return :simplified     if user.profile["reading_speed"] == "slow"
      return :restructured   if user.profile["main_struggle"] == "sentence_length"
    end

    # If no profile exists yet, analyse the text density instead
    # Count average words per sentence - dense text gets bullet points
    words     = text.split.length
    sentences = text.split(/[.!?]+/).reject(&:empty?).length
    return :bullet_points if sentences == 0
    avg = words.to_f / sentences
    avg > 25 ? :bullet_points : :restructured
  end

  # Sends a prompt to Claude and returns the rewritten text back
  def self.call_llm(prompt)
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }]
    )
    response.content.first.text
  rescue => e
    # If Claude API fails, return an error message instead of crashing the app
    "Could not generate this version: #{e.message}"
  end

end
