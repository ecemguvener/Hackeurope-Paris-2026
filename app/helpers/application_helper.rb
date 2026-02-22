module ApplicationHelper
  DEFAULT_DYSLEXIA_BG = "bg-amber-50".freeze
  DYSLEXIA_BG_MAP = {
    "cream" => "bg-amber-50",
    "warm" => "bg-orange-50",
    "mint" => "bg-emerald-50",
    "blue" => "bg-sky-50",
    "gray" => "bg-slate-100"
  }.freeze

  def dyslexia_background_class(user)
    key = user&.profile&.dig("overlay_color").to_s.downcase
    DYSLEXIA_BG_MAP.fetch(key, DEFAULT_DYSLEXIA_BG)
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
    frequencies = words.each_with_object(Hash.new(0)) { |word, acc| acc[word.downcase] += 1 }

    selected_terms = frequencies
      .sort_by { |word, count| [ -count, -word.length ] }
      .map(&:first)
      .first(8)

    return escaped_text if selected_terms.blank?

    pattern = Regexp.union(selected_terms.map { |term| /\b#{Regexp.escape(term)}\b/i })
    escaped_text.gsub(pattern) { |match| %(<strong class="dys-keyword">#{match}</strong>) }
  end
end
