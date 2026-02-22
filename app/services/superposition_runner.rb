class SuperpositionRunner
  PROMPT_TEMPLATES = {
    "simplified" => "Rewrite the following with shorter sentences and clearer structure for someone with dyslexia:\n\n%s",
    "bullet_points" => "Rewrite the following as clear bullet points, scannable and short:\n\n%s",
    "plain_language" => "Rewrite the following replacing all jargon with simple everyday words:\n\n%s",
    "restructured" => "Reorganize the following for easier reading flow with headers and sections:\n\n%s"
  }.freeze

  DENSE_AVG_WORDS_PER_SENTENCE = 22.0
  STYLE_KEYS = Document.style_keys.freeze

  # Returns 4 candidate transformations and an autonomous recommendation.
  # Accepts either a Document or raw text.
  def self.call(document_or_text, user = nil, styles: nil)
    text = source_text(document_or_text)
    return { candidates: [], recommended_style: "simplified", metrics: density_metrics("") } if text.blank?

    metrics = density_metrics(text)
    decision = parallel_style_decision(text, user, metrics)
    recommended = decision[:recommended_style]
    personalization = personalization_instructions(user)

    requested_styles = Array(styles).map(&:to_s).presence || STYLE_KEYS
    candidates = requested_styles.filter_map do |style_key|
      next unless STYLE_KEYS.include?(style_key)

      prompt = build_prompt(style_key, text, personalization)
      content = call_llm(prompt, style_key: style_key, text: text)
      {
        style: style_key,
        title: Document.style_for_key(style_key)&.dig(:title) || style_key.humanize,
        prompt: prompt,
        content: content
      }
    end

    {
      candidates: candidates,
      recommended_style: recommended,
      metrics: metrics,
      decision_trace: decision[:scores]
    }
  end

  def self.recommend_style(document_or_text, user = nil, precomputed_metrics = nil)
    text = source_text(document_or_text)
    metrics = precomputed_metrics || density_metrics(text)
    parallel_style_decision(text, user, metrics)[:recommended_style]
  end

  private

  def self.source_text(document_or_text)
    return document_or_text.to_s unless document_or_text.respond_to?(:extracted_text)

    document_or_text.extracted_text.presence || document_or_text.original_content.to_s
  end

  # Parallel decision making:
  # - onboarding score
  # - behavior/history score
  # - density/content score
  # Combined score chooses the style.
  def self.parallel_style_decision(text, user, metrics)
    scores = STYLE_KEYS.index_with { 0.0 }
    onboarding = onboarding_scores(user)
    history = history_scores(user)
    density = density_scores(metrics)

    STYLE_KEYS.each do |style|
      scores[style] += onboarding.fetch(style, 0.0)
      scores[style] += history.fetch(style, 0.0)
      scores[style] += density.fetch(style, 0.0)
    end

    style, _score = scores.max_by { |_style, score| score }
    { recommended_style: style || "simplified", scores: scores.transform_values { |v| v.round(3) } }
  end

  def self.density_metrics(text)
    words = text.split
    sentences = text.split(/[.!?]+/).map(&:strip).reject(&:empty?)
    sentence_count = sentences.count
    avg_words_per_sentence = sentence_count.zero? ? words.count.to_f : words.count.to_f / sentence_count

    {
      word_count: words.count,
      sentence_count: sentence_count,
      avg_words_per_sentence: avg_words_per_sentence.round(2),
      dense: avg_words_per_sentence >= DENSE_AVG_WORDS_PER_SENTENCE
    }
  end

  def self.onboarding_scores(user)
    profile = user&.profile || {}
    scores = STYLE_KEYS.index_with { 0.0 }

    scores["bullet_points"] += 1.1 if profile["has_dyslexia_pattern"] == true
    scores["plain_language"] += 1.1 if profile["main_struggle"] == "vocabulary"
    scores["simplified"] += 0.9 if profile["reading_speed"] == "slow"
    scores["restructured"] += 0.9 if profile["main_struggle"] == "sentence_length"

    case profile["recommended_style"].to_s
    when "bullet", "bullet_points"
      scores["bullet_points"] += 1.4
    when "simple", "simplified"
      scores["simplified"] += 1.4
    when "structured", "restructured", "chunked"
      scores["restructured"] += 1.4
    when "plain", "plain_language"
      scores["plain_language"] += 1.4
    end

    scores
  end

  def self.history_scores(user)
    counts = user&.superposition_states&.dig("style_counts")
    return STYLE_KEYS.index_with { 0.0 } unless counts.is_a?(Hash) && counts.any?

    total = counts.values.sum(&:to_f)
    return STYLE_KEYS.index_with { 0.0 } if total <= 0.0

    STYLE_KEYS.index_with do |style|
      (counts.fetch(style, 0).to_f / total) * 1.2
    end
  end

  def self.density_scores(metrics)
    scores = STYLE_KEYS.index_with { 0.0 }
    return scores unless metrics

    if metrics[:dense]
      scores["bullet_points"] += 1.0
      scores["restructured"] += 0.4
    else
      scores["simplified"] += 0.4
      scores["plain_language"] += 0.3
    end

    scores
  end

  def self.personalization_instructions(user)
    profile = user&.profile || {}
    lines = []
    lines << "Use short sentence length." if profile["reading_speed"] == "slow" || profile["sentence_length"] == "short"
    lines << "Prefer concrete, everyday vocabulary." if profile["main_struggle"] == "vocabulary" || profile["simplify_jargon"] == true
    lines << "Break ideas into explicit chunks." if profile["main_struggle"] == "sentence_length" || profile["has_dyslexia_pattern"] == true
    lines << "Keep visual scanning easy and predictable."
    lines
  end

  def self.build_prompt(style_key, text, personalization_lines)
    personalization = personalization_lines.map { |line| "- #{line}" }.join("\n")
    <<~PROMPT
      User-specific accessibility instructions:
      #{personalization}

      #{PROMPT_TEMPLATES.fetch(style_key) % text}
    PROMPT
  end

  def self.call_llm(prompt, style_key:, text:)
    api_key = ENV["ANTHROPIC_API_KEY"]
    raise "Missing ANTHROPIC_API_KEY" if api_key.blank?

    client = Anthropic::Client.new(api_key: api_key)
    response = client.messages.create(
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [ { role: "user", content: prompt } ]
    )
    response.content.first.text.to_s.strip
  rescue => e
    Rails.logger.error("SuperpositionRunner Claude error: #{e.message}")
    fallback_transform(style_key, text)
  end

  def self.fallback_transform(style_key, text)
    cleaned = text.to_s.strip
    return "" if cleaned.blank?

    sentences = cleaned.split(/(?<=[.!?])\s+/).reject(&:blank?)

    case style_key.to_s
    when "bullet_points"
      sentences.first(8).map { |sentence| "- #{sentence.strip}" }.join("\n")
    when "plain_language"
      cleaned.gsub(/\b(utilize|approximately|commence|terminate)\b/i,
        "use")
    when "restructured"
      parts = sentences.each_slice(3).to_a
      parts.each_with_index.map { |chunk, idx| "Section #{idx + 1}\n#{chunk.join(' ')}" }.join("\n\n")
    else
      sentences.map { |sentence| sentence.split.first(14).join(" ") }.join(". ")
    end
  end
end
