class AddAudioUrlToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :audio_url, :string
  end
end
