require "rails_helper"

RSpec.describe SuperpositionRunner do
  let(:user) { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }

  describe ".call" do
    before do
      allow(described_class).to receive(:call_llm_bulk).and_return(
        {
          "simplified" => "transformed text",
          "bullet_points" => "transformed text",
          "plain_language" => "transformed text",
          "restructured" => "transformed text"
        }
      )
    end

    it "returns 4 style candidates" do
      result = described_class.call("A short paragraph for testing.", user)

      expect(result[:candidates].size).to eq(4)
      expect(result[:candidates].map { |c| c[:style] }).to match_array(Document.style_keys)
      expect(result[:candidates].all? { |c| c[:content].present? }).to be(true)
    end

    it "can generate only one requested style" do
      allow(described_class).to receive(:call_llm_bulk).and_return({ "plain_language" => "transformed text" })
      result = described_class.call("A short paragraph for testing.", user, styles: [ "plain_language" ])

      expect(result[:candidates].size).to eq(1)
      expect(result[:candidates].first[:style]).to eq("plain_language")
    end

    it "auto-recommends bullet points for dense text" do
      dense_text = "This is a very long and complicated sentence with many clauses and terms that raises cognitive load significantly for the reader while also introducing technical language, multiple nested qualifiers, and several context switches that make quick scanning difficult for many users. " \
        "Another sentence continues in a similarly dense way to keep average sentence length high with additional complexity, long phrase chains, and abstract wording that increases processing load."

      result = described_class.call(dense_text, user)
      expect(result[:recommended_style]).to eq("bullet_points")
      expect(result[:metrics][:dense]).to be(true)
    end

    it "uses onboarding profile signals to choose a user-specific style" do
      user.update!(
        profile: {
          "main_struggle" => "vocabulary",
          "recommended_style" => "plain_language",
          "reading_speed" => "medium"
        }
      )

      result = described_class.call("Short technical text with jargon.", user)
      expect(result[:recommended_style]).to eq("plain_language")
      expect(result[:decision_trace]["plain_language"]).to be > result[:decision_trace]["simplified"]
    end

    it "injects user-specific personalization instructions into prompts" do
      user.update!(profile: { "simplify_jargon" => true, "reading_speed" => "slow" })

      result = described_class.call("Text to transform.", user)
      prompt = result[:candidates].first[:prompt]

      expect(prompt).to include("User-specific accessibility instructions:")
      expect(prompt).to include("Use short sentence length.")
      expect(prompt).to include("Prefer concrete, everyday vocabulary.")
    end

    it "uses style history from user state when available" do
      user.update!(superposition_states: { "style_counts" => { "plain_language" => 4, "simplified" => 1 } })

      result = described_class.call("Short text.", user)
      expect(result[:recommended_style]).to eq("plain_language")
    end
  end
end
