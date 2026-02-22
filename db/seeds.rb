user = User.find_or_create_by!(name: "Demo User") do |u|
  u.profile = {
    sentence_length: "short",
    font_preference: "sans-serif",
    color_overlay: "none",
    simplify_jargon: true,
    bullet_points: true,
    max_paragraph_length: 3,
    line_spacing: "relaxed",
    highlight_keywords: true
  }
  u.superposition_states = {
    short_form: { intensity: "minimal", transformations: [ "spacing" ] },
    long_form: { intensity: "moderate", transformations: %w[simplify bullets spacing] },
    technical: { intensity: "maximum", transformations: %w[simplify jargon bullets restructure] }
  }
  u.preferred_style = nil
end

# Ensure Demo User has an API token for the Chrome extension
if user.api_token.blank?
  user.update!(api_token: SecureRandom.hex(32))
end

puts "Seeded demo user: #{user.name}"
puts "API Token: #{user.api_token}"
