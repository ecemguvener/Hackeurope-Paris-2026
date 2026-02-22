module ApplicationHelper
  DEFAULT_DYSLEXIA_BG = "bg-amber-50".freeze
  DYSLEXIA_BG_MAP = {
    "cream" => "bg-amber-50",
    "warm" => "bg-orange-50",
    "mint" => "bg-emerald-50",
    "blue" => "bg-sky-50",
    "gray" => "bg-slate-100"
  }.freeze
  DYSLEXIA_FONT_MAP = {
    "sans-serif" => "dys-font-sans",
    "serif" => "dys-font-serif",
    "mono" => "dys-font-mono",
    "open_dyslexic" => "dys-font-open"
  }.freeze
  DYSLEXIA_SIZE_MAP = {
    "normal" => "dys-size-normal",
    "large" => "dys-size-large",
    "xlarge" => "dys-size-xlarge"
  }.freeze
  KEYWORD_STOPWORDS = %w[
    about above after again against almost another because before between
    could details every first found have here information into just keep
    maybe might often original other plain section should since some
    summary than that their there these they this through very version
    where while which would
  ].freeze

  def dyslexia_background_class(user)
    key = user&.profile&.dig("overlay_color").to_s.downcase
    DYSLEXIA_BG_MAP.fetch(key, DEFAULT_DYSLEXIA_BG)
  end

  def dyslexia_font_class(user)
    key = user&.profile&.dig("font_preference").to_s.downcase
    DYSLEXIA_FONT_MAP.fetch(key, "dys-font-sans")
  end

  def dyslexia_size_class(user)
    profile = user&.profile || {}
    key = profile["text_size"].to_s.downcase
    return DYSLEXIA_SIZE_MAP.fetch(key, "dys-size-normal") if key.present?

    profile["reading_speed"] == "slow" ? "dys-size-large" : "dys-size-normal"
  end

  def dyslexia_reading_classes(user)
    [
      "dyslexia-content dyslexia-surface",
      dyslexia_background_class(user),
      dyslexia_font_class(user),
      dyslexia_size_class(user)
    ].join(" ")
  end

  def dyslexia_reading_html(text)
    raw_text = text.to_s
    return "" if raw_text.blank?

    escaped = ERB::Util.html_escape(raw_text)
    highlighted = highlight_keywords(escaped)
    simple_format(highlighted, {}, sanitize: false)
  end

  private

  # Heuristic keyword emphasis: highlight a few longer repeated terms to improve scanning.
  def highlight_keywords(escaped_text)
    words = escaped_text.scan(/\b[A-Za-z][A-Za-z'-]{5,}\b/)
    frequencies = words.each_with_object(Hash.new(0)) do |word, acc|
      normalized = word.downcase
      next if KEYWORD_STOPWORDS.include?(normalized)

      acc[normalized] += 1
    end

    selected_terms = frequencies
      .select { |_word, count| count >= 2 }
      .sort_by { |word, count| [ -count, -word.length ] }
      .map(&:first)
      .first(6)

    if selected_terms.blank?
      selected_terms = frequencies
        .sort_by { |word, count| [ -word.length, -count ] }
        .map(&:first)
        .first(4)
    end

    return escaped_text if selected_terms.blank?

    pattern = Regexp.union(selected_terms.map { |term| /\b#{Regexp.escape(term)}\b/i })
    escaped_text.gsub(pattern) { |match| %(<strong class="dys-keyword">#{match}</strong>) }
  end
end
