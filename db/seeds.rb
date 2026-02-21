User.find_or_create_by!(name: "Demo User") do |user|
  user.profile = {
    sentence_length: "short",
    font_preference: "sans-serif",
    color_overlay: "none",
    simplify_jargon: true,
    bullet_points: true,
    max_paragraph_length: 3,
    line_spacing: "relaxed",
    highlight_keywords: true
  }
  user.superposition_states = {
    short_form: { intensity: "minimal", transformations: [ "spacing" ] },
    long_form: { intensity: "moderate", transformations: %w[simplify bullets spacing] },
    technical: { intensity: "maximum", transformations: %w[simplify jargon bullets restructure] }
  }
  user.preferred_style = nil
end

puts "Seeded demo user: #{User.first.name}"
