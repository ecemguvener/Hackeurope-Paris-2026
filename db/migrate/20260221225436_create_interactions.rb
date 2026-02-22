class CreateInteractions < ActiveRecord::Migration[8.1]
  def change
    create_table :interactions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :page_url
      t.string :page_title
      t.string :action_type
      t.text :input_text
      t.text :output_text
      t.string :style
      t.jsonb :metadata

      t.timestamps
    end
  end
end
