require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let!(:user) do
    User.create!(
      name: "Demo User",
      profile: {
        sentence_length: "short",
        font_preference: "sans-serif",
        simplify_jargon: true
      },
      superposition_states: {}
    )
  end

  describe "GET /profile" do
    it "renders the profile page" do
      get profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your Profile")
    end

    context "with a preferred style" do
      before { user.update!(preferred_style: "Bullet Points") }

      it "displays the preferred style" do
        get profile_path
        expect(response.body).to include("Bullet Points")
      end
    end

    context "without a preferred style" do
      it "displays the empty state message" do
        get profile_path
        expect(response.body).to include("No preference saved yet")
        expect(response.body).to include("upload a document")
      end
    end

    context "with accessibility profile settings" do
      it "displays the profile settings" do
        get profile_path
        expect(response.body).to include("Sentence Length")
        expect(response.body).to include("short")
        expect(response.body).to include("Font Preference")
        expect(response.body).to include("sans-serif")
      end
    end

    context "with documents in history" do
      let!(:doc_with_selection) do
        user.documents.create!(
          original_content: "text",
          content_hash: "aaa",
          selected_version: 2,
          created_at: 1.day.ago
        )
      end

      let!(:doc_without_selection) do
        user.documents.create!(
          original_content: "text",
          content_hash: "bbb",
          created_at: Time.current
        )
      end

      it "lists documents ordered by most recent first" do
        get profile_path
        expect(response.body).to include("Document History")
        # Most recent doc appears - has "Not yet chosen"
        expect(response.body).to include("Not yet chosen")
        # Older doc has a selected style
        expect(response.body).to include("Bullet Points")
      end
    end

    context "with no documents" do
      it "displays the empty state" do
        get profile_path
        expect(response.body).to include("No documents yet")
        expect(response.body).to include("Upload a Document")
      end
    end
  end

  describe "POST /profile/assessment" do
    it "updates profile via reading test analyser inputs" do
      post profile_assessment_path, params: {
        retyped_text: "The cat wearing a hat sat on the mat",
        self_described_difficulty: "Long words and skipping words",
        time_taken_seconds: 9
      }

      user.reload
      expect(response).to redirect_to(profile_path)
      expect(user.profile).to be_present
      expect(user.preferred_style).to be_present
    end
  end

  describe "PATCH /profile/readability" do
    it "sets readability mode to strong" do
      patch profile_readability_path, params: { mode: "strong" }

      user.reload
      expect(response).to redirect_to(profile_path)
      expect(user.profile["readability_mode"]).to eq("strong")
    end

    it "rejects invalid readability mode" do
      patch profile_readability_path, params: { mode: "bad" }

      user.reload
      expect(response).to redirect_to(profile_path)
      expect(user.profile["readability_mode"]).to be_nil
    end
  end
end
