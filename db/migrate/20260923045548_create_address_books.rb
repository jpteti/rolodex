class CreateAddressBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :address_books do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false, default: "Contacts"
      t.integer :ctag, null: false, default: 0

      t.timestamps
    end
  end
end
