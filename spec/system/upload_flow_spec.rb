require "rails_helper"

RSpec.describe "Upload flow", type: :system do
  before do
    User.create!(
      name: "Demo User",
      profile: { "assessment_completed" => true, "recommended_style" => "bullet_points" },
      superposition_states: {}
    )
  end

  it "allows uploading a text file and redirects to auto-selected view" do
    visit upload_path
    expect(page).to have_content("Upload Content")
    expect(page).to have_button("Transform My Content")

    attach_file "document[file]", Rails.root.join("spec/fixtures/files/test.txt")
    click_button "Transform My Content"

    expect(page).to have_content("Your Optimized Content")
  end

  it "shows an error when submitting without a file" do
    visit upload_path
    click_button "Transform My Content"

    expect(page).to have_content("Please select a file to upload")
  end

  it "shows assessment step on upload when assessment is missing" do
    User.find_by(name: "Demo User")&.update!(profile: {})

    visit upload_path

    expect(page).to have_current_path(upload_path)
    expect(page).to have_content("Step 1: Reading Assessment")
    expect(page).to have_button("Save & Continue")
  end
end
