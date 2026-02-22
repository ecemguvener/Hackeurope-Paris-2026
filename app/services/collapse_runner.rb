class CollapseRunner
  LONG_DWELL_MS = 25_000

  # Collapses the superposition into one final version and updates learning state.
  # chosen_style can be nil and will then be inferred from signals/history.
  def self.call(document, chosen_style = nil, signals = {})
    user = document.user
    normalized_signals = normalize_signals(signals)
    style_key = pick_style(document, user, chosen_style, normalized_signals)
    selected_version = Document.selected_version_for_style(style_key)
    content = document.transformations&.dig(style_key, "content").presence ||
      document.extracted_text.presence ||
      document.original_content.to_s

    Document.transaction do
      document.update!(selected_version: selected_version) if selected_version
      apply_learning!(user, style_key, normalized_signals)
    end

    {
      style: style_key,
      selected_version: selected_version,
      title: Document.style_for_key(style_key)&.dig(:title) || style_key.humanize,
      content: content,
      signals: normalized_signals,
      profile_updates: {
        preferred_style: user.preferred_style,
        style_counts: user.superposition_states["style_counts"]
      }
    }
  end

  private

  def self.pick_style(document, user, chosen_style, signals)
    normalized = normalize_style(chosen_style)
    return normalized if style_available?(document, normalized)

    signal_style = infer_from_signals(signals)
    return signal_style if style_available?(document, signal_style)

    text = document.extracted_text.presence || document.original_content.to_s
    auto_style = SuperpositionRunner.recommend_style(text, user)
    return auto_style if style_available?(document, auto_style)

    first_available_style(document) || "simplified"
  end

  def self.normalize_style(style)
    key = style.to_s
    return nil if key.blank?
    return key if Document.style_keys.include?(key)

    transformed = key.parameterize(separator: "_")
    return transformed if Document.style_keys.include?(transformed)

    title_match = Document::TRANSFORMATION_STYLES.find { |s| s[:title].casecmp?(key) }
    title_match&.dig(:key)
  end

  def self.style_available?(document, style_key)
    return false if style_key.blank?

    content = document.transformations&.dig(style_key, "content")
    content.present?
  end

  def self.first_available_style(document)
    Document.style_keys.find { |style_key| style_available?(document, style_key) }
  end

  # Optional micro-signals:
  # - dwell_ms: if very long, default to bullets for scanability.
  # - tts_style: if user played TTS for one style, treat it as stronger signal.
  def self.infer_from_signals(signals)
    tts_style = normalize_style(signals[:tts_style] || signals["tts_style"])
    return tts_style if tts_style.present?

    dwell_ms = signals[:dwell_ms].to_i
    return "bullet_points" if dwell_ms >= LONG_DWELL_MS

    nil
  end

  def self.normalize_signals(signals)
    return {} if signals.blank?

    {
      dwell_ms: (signals[:dwell_ms] || signals["dwell_ms"]).to_i,
      tts_style: normalize_style(signals[:tts_style] || signals["tts_style"])
    }.compact
  end

  def self.apply_learning!(user, style_key, signals)
    profile = (user.profile || {}).deep_dup
    states = (user.superposition_states || {}).deep_dup

    states["style_counts"] ||= {}
    states["style_counts"][style_key] = states["style_counts"].fetch(style_key, 0).to_i + 1

    states["signal_counts"] ||= {}
    states["signal_counts"]["long_dwell_events"] = states["signal_counts"].fetch("long_dwell_events", 0).to_i + 1 if signals[:dwell_ms].to_i >= LONG_DWELL_MS
    states["signal_counts"]["tts_events"] = states["signal_counts"].fetch("tts_events", 0).to_i + 1 if signals[:tts_style].present?
    states["last_selected_style"] = style_key

    profile["preferred_style"] = style_key
    profile["style_weights"] = build_style_weights(states["style_counts"])

    preferred_title = Document.style_for_key(style_key)&.dig(:title) || style_key.humanize

    user.update!(
      preferred_style: preferred_title,
      profile: profile,
      superposition_states: states
    )
  end

  def self.build_style_weights(style_counts)
    total = style_counts.values.sum(&:to_f)
    return {} if total <= 0.0

    style_counts.transform_values { |count| (count.to_f / total).round(3) }
  end
end
