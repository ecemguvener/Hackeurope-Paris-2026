require "rails_helper"

RSpec.describe CollapseRunner do
  let(:user) { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }
  let(:document) do
    user.documents.create!(
      original_content: "Original content",
      extracted_text: "Extracted content",
      content_hash: "collapse-spec-1",
      transformations: {
        "simplified" => { "content" => "Simple text." },
        "bullet_points" => { "content" => "- A\n- B" },
        "plain_language" => { "content" => "Plain words." },
        "restructured" => { "content" => "Sectioned text." }
      }
    )
  end

  describe ".call" do
    it "uses the chosen style and updates learning state" do
      result = described_class.call(document, "plain_language", dwell_ms: 30_000)

      expect(result[:style]).to eq("plain_language")
      expect(result[:selected_version]).to eq(3)
      expect(result[:content]).to eq("Plain words.")

      document.reload
      user.reload

      expect(document.selected_version).to eq(3)
      expect(user.preferred_style).to eq("Plain Language")
      expect(user.superposition_states.dig("style_counts", "plain_language")).to eq(1)
      expect(user.profile.dig("style_weights", "plain_language")).to eq(1.0)
      expect(user.superposition_states.dig("signal_counts", "long_dwell_events")).to eq(1)
    end

    it "can infer style from micro-signals when chosen style is missing" do
      result = described_class.call(document, nil, tts_style: "bullet_points")

      expect(result[:style]).to eq("bullet_points")
      expect(result[:selected_version]).to eq(2)

      document.reload
      user.reload

      expect(document.selected_version).to eq(2)
      expect(user.preferred_style).to eq("Bullet Points")
      expect(user.superposition_states.dig("signal_counts", "tts_events")).to eq(1)
    end
  end
end
