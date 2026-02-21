require "rails_helper"

RSpec.describe "Navigation", type: :system do
  before { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }

  it "displays the nav bar on every page with Upload and Profile links" do
    visit root_path
    within("nav") do
      expect(page).to have_link("Qlarity")
      expect(page).to have_link("Upload")
      expect(page).to have_link("Profile")
    end
  end

  it "highlights the active nav link on upload page" do
    visit upload_path
    within("nav") do
      expect(page).to have_link("Upload")
    end
  end

  it "has a skip to main content link" do
    visit root_path
    expect(page).to have_css("a[href='#main-content']", text: "Skip to main content", visible: :all)
  end

  it "has a main landmark with correct id" do
    visit root_path
    expect(page).to have_css("main#main-content")
  end
end
