class CreateAppPasswords < ActiveRecord::Migration[8.1]
  def change
    create_table :app_passwords do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :secret_digest, null: false
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :app_passwords, :secret_digest, unique: true
  end
end
