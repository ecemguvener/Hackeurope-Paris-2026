require "rails_helper"

RSpec.describe "Home page", type: :system do
  before { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }

  it "displays the hero section with CTA buttons" do
    visit root_path

    expect(page).to have_content("Qlarity")
    expect(page).to have_content("AI-Powered Reading Optimization")
    expect(page).to have_link("Get Started")
    expect(page).to have_link("View Profile")
  end

  it "displays the feature highlight cards" do
    visit root_path

    expect(page).to have_content("Upload")
    expect(page).to have_content("Transform")
    expect(page).to have_content("Pick & Save")
  end

  it "Get Started links to upload page" do
    visit root_path
    click_link "Get Started"

    expect(page).to have_current_path(upload_path)
  end

  it "View Profile links to profile page" do
    visit root_path
    click_link "View Profile"

    expect(page).to have_current_path(profile_path)
  end
end
