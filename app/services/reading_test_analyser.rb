class ReadingTestAnalyser
  TEST_SENTENCE = "The cat wearing a hat sat on the mat staring at a rat".freeze

  def self.call(user, retyped_text:, self_described_difficulty:, time_taken_seconds:, typing_metrics_json: nil)
    typo_analysis = analyse_retype(retyped_text)
    typing_metrics = parse_metrics(typing_metrics_json)
    heuristic_profile = heuristic_profile_for(typo_analysis, time_taken_seconds, typing_metrics)

    prompt = build_prompt(
      retyped_text: retyped_text,
      self_described_difficulty: self_described_difficulty,
      time_taken_seconds: time_taken_seconds,
      typo_analysis: typo_analysis,
      typing_metrics: typing_metrics,
      heuristic_profile: heuristic_profile
    )

    result = call_llm(prompt)
    parsed = JSON.parse(result)
    parsed = normalize_profile(parsed, heuristic_profile)

    user.profile.merge!(parsed)
    user.preferred_style = parsed["recommended_style"]
    user.save

    parsed
  end

  def self.analyse_retype(retyped)
    original_words = TEST_SENTENCE.downcase.split
    retyped_words = retyped.to_s.downcase.split
    skipped_words = original_words - retyped_words

    original = normalize_text(TEST_SENTENCE)
    typed = normalize_text(retyped)
    distance = levenshtein_distance(original, typed)
    max_len = [ original.length, 1 ].max
    accuracy = ((1.0 - (distance.to_f / max_len)) * 100).round.clamp(0, 100)

    {
      skipped_words: skipped_words,
      skipped_count: skipped_words.length,
      character_distance: distance,
      accuracy_score: accuracy
    }
  end

  def self.call_llm(prompt)
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 512,
      messages: [ { role: "user", content: prompt } ]
    )
    response.content.first.text
  rescue
    JSON.generate({
      "reading_speed" => "medium",
      "comprehension_score" => 55,
      "main_struggle" => "general",
      "has_dyslexia_pattern" => false,
      "recommended_style" => "bullet",
      "assessment" => "Could not analyse right now, using a safe fallback."
    })
  end

  def self.build_prompt(retyped_text:, self_described_difficulty:, time_taken_seconds:, typo_analysis:, typing_metrics:, heuristic_profile:)
    <<~PROMPT
      A user completed a short reading retype test. Return ONLY JSON with this exact shape:
      {
        "reading_speed": "slow / medium / fast",
        "comprehension_score": 0-100,
        "main_struggle": "vocabulary / sentence_length / letter_swapping / word_skipping / general",
        "has_dyslexia_pattern": true or false,
        "recommended_style": "bullet / simple / chunked / structured",
        "assessment": "one short sentence with what helps this user"
      }

      TEST INPUT:
      - Original sentence: "#{TEST_SENTENCE}"
      - Retyped sentence: "#{retyped_text}"
      - Hidden timer seconds: #{time_taken_seconds}
      - Skipped words: #{typo_analysis[:skipped_words]}
      - Skip count: #{typo_analysis[:skipped_count]}
      - Character distance: #{typo_analysis[:character_distance]}
      - Accuracy score: #{typo_analysis[:accuracy_score]}
      - Hidden typing metrics: #{typing_metrics.to_json}
      - User self-described difficulty: "#{self_described_difficulty}"

      HEURISTIC BASELINE (can override if needed):
      #{heuristic_profile.to_json}
    PROMPT
  end

  def self.parse_metrics(json_str)
    parsed = JSON.parse(json_str.to_s)
    return {} unless parsed.is_a?(Hash)

    parsed.slice(
      "hidden_timer_seconds",
      "active_typing_seconds",
      "pauses",
      "backspaces",
      "edits"
    )
  rescue JSON::ParserError
    {}
  end

  def self.heuristic_profile_for(typo_analysis, time_taken_seconds, metrics)
    seconds = [ time_taken_seconds.to_f, 1.0 ].max
    words = TEST_SENTENCE.split.length
    wpm = (words / seconds * 60.0).round(1)

    speed = if wpm < 18
      "slow"
    elsif wpm < 35
      "medium"
    else
      "fast"
    end

    backspaces = metrics.fetch("backspaces", 0).to_i
    pauses = metrics.fetch("pauses", 0).to_i
    skipped = typo_analysis[:skipped_count].to_i
    accuracy = typo_analysis[:accuracy_score].to_i

    struggle = if skipped >= 2
      "word_skipping"
    elsif backspaces >= 4
      "letter_swapping"
    elsif accuracy < 65
      "sentence_length"
    else
      "general"
    end

    recommended_style = case struggle
    when "word_skipping"
      "bullet"
    when "letter_swapping"
      "simple"
    when "sentence_length"
      "chunked"
    else
      speed == "slow" ? "bullet" : "simple"
    end

    {
      "reading_speed" => speed,
      "comprehension_score" => [ accuracy - (skipped * 5) - (pauses * 2), 20 ].max,
      "main_struggle" => struggle,
      "has_dyslexia_pattern" => (skipped >= 2 || backspaces >= 4 || accuracy < 70),
      "recommended_style" => recommended_style,
      "assessment" => "Hidden-timer test suggests #{struggle.tr('_', ' ')}; #{recommended_style} formatting may help most."
    }
  end

  def self.normalize_profile(profile, fallback)
    normalized = fallback.merge(profile.transform_keys(&:to_s))
    normalized["comprehension_score"] = normalized["comprehension_score"].to_i.clamp(0, 100)
    normalized["has_dyslexia_pattern"] = !!normalized["has_dyslexia_pattern"]
    normalized["recommended_style"] = normalized["recommended_style"].to_s
    normalized
  end

  def self.normalize_text(text)
    text.to_s.downcase.gsub(/[^a-z0-9\s]/, " ").gsub(/\s+/, " ").strip
  end

  def self.levenshtein_distance(a, b)
    a_chars = a.chars
    b_chars = b.chars
    rows = Array.new(a_chars.length + 1) { |i| [ i ] }
    rows[0] = (0..b_chars.length).to_a

    (1..a_chars.length).each do |i|
      (1..b_chars.length).each do |j|
        cost = a_chars[i - 1] == b_chars[j - 1] ? 0 : 1
        rows[i][j] = [
          rows[i - 1][j] + 1,
          rows[i][j - 1] + 1,
          rows[i - 1][j - 1] + cost
        ].min
      end
    end

    rows[a_chars.length][b_chars.length]
  end
end
