require "rails_helper"

RSpec.describe "Upload flow", type: :system do
  before { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }

  it "allows uploading a text file and redirects to one personalized result" do
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
end
