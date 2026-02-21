class ReadingTestAnalyser
  # The sentence shown to the user on screen to retype
  # In capitals because it never changes - it is a constant
  TEST_SENTENCE = "The cat wearing a hat sat on the mat staring at a rat"

  # Main function - Person 1 calls this when the user submits the reading test form
  # It receives: who the user is, what they typed, what they said their difficulty is, how long they took
  def self.call(user, retyped_text:, self_described_difficulty:, time_taken_seconds:)

    # Step 1: Compare what they typed vs the original sentence to find mistakes
    typo_analysis = analyse_retype(retyped_text)

    # Step 2: Build a prompt for the Claude with all the test results to give it to Claude API 
    prompt = <<~PROMPT
      A user just completed a reading test. Analyse their results and return a JSON profile.

      RETYPE TEST:
      - Original sentence: "#{TEST_SENTENCE}"
      - What they typed:   "#{retyped_text}"
      - Time taken:        #{time_taken_seconds} seconds
      - Words they skipped: #{typo_analysis[:skipped_words]}

      WHAT THEY SAID ABOUT THEIR OWN DIFFICULTY:
      "#{self_described_difficulty}"

      Based on this, return ONLY a valid JSON object with these fields:
      {
        "reading_speed": "slow / medium / fast",
        "comprehension_score": 0-100,
        "main_struggle": "vocabulary / sentence_length / letter_swapping / word_skipping / general",
        "has_dyslexia_pattern": true or false,
        "recommended_style": "bullet / simple / chunked / structured",
        "assessment": "one sentence describing how this person struggles and what will help them"
      }
    PROMPT

    # Step 3: Send the prompt to Claude and get back the reading profile
    result = call_llm(prompt)

    # Step 4: Parse Claude's response from text into a Ruby hash
    parsed = JSON.parse(result)

    # Step 5: Save the profile to the user in the database so it persists
    user.profile.merge!(parsed)
    user.preferred_style = parsed["recommended_style"]
    user.save

    # Return the parsed profile so Person 1 can use it on the next page
    parsed
  end

  # Helper function: compares what the user typed vs the original sentence
  # Returns a hash with the words they skipped
  def self.analyse_retype(retyped)
    # Split the original sentence into individual words, lowercased
    original_words = TEST_SENTENCE.downcase.split

    # Split what the user typed into individual words, lowercased
    retyped_words = retyped.downcase.split

    # Find words that are in the original but missing from what they typed
    skipped_words = original_words - retyped_words

    # Return the result as a hash
    { skipped_words: skipped_words }
  end

  # Sends the prompt to Claude and returns the response text
  def self.call_llm(prompt)
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 512,
      messages: [{ role: "user", content: prompt }]
    )
    response.content.first.text
  rescue => e
    # If the API fails, return a safe default profile so the app does not crash
    JSON.generate({
      "reading_speed"       => "medium",
      "comprehension_score" => 50,
      "main_struggle"       => "general",
      "has_dyslexia_pattern" => false,
      "recommended_style"   => "bullet",
      "assessment"          => "Could not analyse at this time. Defaulting to bullet style."
    })
  end

end
