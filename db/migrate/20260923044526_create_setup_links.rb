class CreateSetupLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :setup_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :setup_links, :token_digest, unique: true
  end
end
