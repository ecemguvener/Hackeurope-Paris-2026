class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.text :original_content
      t.text :extracted_text
      t.jsonb :transformations, default: {}
      t.integer :selected_version
      t.string :content_hash

      t.timestamps
    end

    add_index :documents, :content_hash
  end
end
