require "rails_helper"

RSpec.describe "Results and collapse flow", type: :system do
  let!(:user) { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }

  let!(:document_with_transforms) do
    user.documents.create!(
      original_content: "Dense corporate jargon text.",
      content_hash: "sys-test-1",
      transformations: {
        "simplified" => { "content" => "Simple version." },
        "bullet_points" => { "content" => "- Point one\n- Point two" },
        "plain_language" => { "content" => "Easy to read." },
        "restructured" => { "content" => "Reorganized." }
      }
    )
  end

  it "displays 4 transformation cards on results page" do
    visit results_path(document_with_transforms)

    expect(page).to have_content("Simplified")
    expect(page).to have_content("Bullet Points")
    expect(page).to have_content("Plain Language")
    expect(page).to have_content("Restructured")
    expect(page).to have_content("Simple version.")
    expect(page).to have_content("Easy to read.")
  end

  it "shows toggle buttons for original content" do
    visit results_path(document_with_transforms)
    expect(page).to have_button("Show Original", count: 4)
  end

  it "shows Pick This Version buttons" do
    visit results_path(document_with_transforms)
    expect(page).to have_link("Pick This Version", count: 4)
  end

  it "shows placeholder cards when transformations are not ready" do
    doc = user.documents.create!(original_content: "test", content_hash: "sys-test-2")
    visit results_path(doc)

    expect(page).to have_content("Processing transformation...")
  end

  it "displays the collapsed view after picking a version" do
    document_with_transforms.update!(selected_version: 2)
    visit collapsed_show_path(document_with_transforms)

    expect(page).to have_content("You chose: Bullet Points")
    expect(page).to have_content("Point one")
    expect(page).to have_link("Back to All Versions")
    expect(page).to have_link("Upload New Document")
  end

  it "redirects to results when visiting collapsed without a selection" do
    doc = user.documents.create!(original_content: "test", content_hash: "sys-test-3")
    visit collapsed_show_path(doc)

    expect(page).to have_current_path(results_path(doc))
  end
end
