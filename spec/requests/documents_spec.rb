require "rails_helper"

RSpec.describe "Documents", type: :request do
  let!(:user) { User.create!(name: "Demo User", profile: {}, superposition_states: {}) }

  describe "GET /upload" do
    it "renders the upload form" do
      get upload_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Transform My Content")
      expect(response.body).to include('accept=".txt,.pdf,.png,.jpg,.jpeg"')
    end
  end

  describe "POST /upload" do
    context "with a valid text file" do
      let(:file) { fixture_file_upload("test.txt", "text/plain") }

      it "creates a document and redirects to results" do
        expect {
          post upload_path, params: { document: { file: file } }
        }.to change(Document, :count).by(1)

        document = Document.last
        expect(document.file).to be_attached
        expect(document.extracted_text).to include("sample text")
        expect(document.content_hash).to be_present
        expect(document.user).to eq(user)
        expect(response).to redirect_to(results_path(document))
      end
    end

    context "with a valid PDF file" do
      let(:file) { fixture_file_upload("test.pdf", "application/pdf") }

      it "creates a document and redirects to results" do
        expect {
          post upload_path, params: { document: { file: file } }
        }.to change(Document, :count).by(1)

        document = Document.last
        expect(document.file).to be_attached
        expect(response).to redirect_to(results_path(document))
      end
    end

    context "with a valid image file" do
      let(:file) { fixture_file_upload("test.png", "image/png") }

      it "creates a document and redirects to results" do
        expect {
          post upload_path, params: { document: { file: file } }
        }.to change(Document, :count).by(1)

        document = Document.last
        expect(document.file).to be_attached
        expect(response).to redirect_to(results_path(document))
      end
    end

    context "without a file" do
      it "renders the upload form with an error" do
        post upload_path, params: { document: { file: nil } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Please select a file to upload")
      end
    end
  end

  describe "GET /results/:id" do
    context "when transformations are not ready" do
      let!(:document) { user.documents.create!(original_content: "test content here", content_hash: "abc") }

      it "renders the results page with placeholder cards" do
        get results_path(document)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Transformation Results")
        expect(response.body).to include("Simplified")
        expect(response.body).to include("Bullet Points")
        expect(response.body).to include("Plain Language")
        expect(response.body).to include("Restructured")
        expect(response.body).to include("Processing transformation...")
      end

      it "shows original content below placeholder cards" do
        get results_path(document)
        expect(response.body).to include("Original Content")
        expect(response.body).to include("test content here")
      end
    end

    context "when transformations are ready" do
      let!(:document) do
        user.documents.create!(
          original_content: "Dense corporate jargon text.",
          content_hash: "def",
          transformations: {
            "simplified" => { "content" => "Simple version of the text." },
            "bullet_points" => { "content" => "- Point one\n- Point two" },
            "plain_language" => { "content" => "Easy to read version." },
            "restructured" => { "content" => "Reorganized text here." }
          }
        )
      end

      it "renders 4 transformation cards with content" do
        get results_path(document)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Simple version of the text.")
        expect(response.body).to include("Point one")
        expect(response.body).to include("Easy to read version.")
        expect(response.body).to include("Reorganized text here.")
      end

      it "includes toggle buttons for original content" do
        get results_path(document)
        expect(response.body).to include("Show Original")
        expect(response.body).to include('data-action="toggle#toggle"')
      end

      it "includes Pick This Version buttons" do
        get results_path(document)
        expect(response.body).to include("Pick This Version")
      end

      it "preserves original content in hidden toggle targets" do
        get results_path(document)
        expect(response.body).to include("Dense corporate jargon text.")
      end
    end
  end
end
