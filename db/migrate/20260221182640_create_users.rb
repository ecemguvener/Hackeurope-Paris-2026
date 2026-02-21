class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.jsonb :profile, default: {}
      t.jsonb :superposition_states, default: {}
      t.string :preferred_style

      t.timestamps
    end
  end
end
