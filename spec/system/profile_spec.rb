require "rails_helper"

RSpec.describe "Profile page", type: :system do
  let!(:user) do
    User.create!(
      name: "Demo User",
      profile: { sentence_length: "short", font_preference: "sans-serif" },
      superposition_states: {}
    )
  end

  it "displays preferred style when set" do
    user.update!(preferred_style: "Bullet Points")
    visit profile_path

    expect(page).to have_content("Your Profile")
    expect(page).to have_content("Bullet Points")
  end

  it "shows empty state when no preferred style" do
    visit profile_path

    expect(page).to have_content("No preference saved yet")
    expect(page).to have_link("upload a document")
  end

  it "displays accessibility profile settings" do
    visit profile_path

    expect(page).to have_content("Sentence Length")
    expect(page).to have_content("short")
    expect(page).to have_content("Font Preference")
    expect(page).to have_content("sans-serif")
  end

  it "displays document history" do
    user.documents.create!(
      original_content: "text",
      content_hash: "prof-1",
      selected_version: 1,
      transformations: { "simplified" => { "content" => "simple" } },
      created_at: 1.day.ago
    )

    visit profile_path
    expect(page).to have_content("Document History")
    expect(page).to have_content("Simplified")
  end

  it "shows empty state when no documents" do
    visit profile_path

    expect(page).to have_content("No documents yet")
    expect(page).to have_link("Upload a Document")
  end
end
