class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :address_book, null: false, foreign_key: true
      t.string :uid, null: false
      t.string :resource_name, null: false
      t.text :vcard, null: false
      t.string :etag, null: false
      t.string :display_name, null: false
      t.string :given_name
      t.string :family_name
      t.string :organization
      t.text :emails
      t.text :phones
      t.string :sort_key, null: false

      t.timestamps
    end
    add_index :contacts, [ :address_book_id, :uid ], unique: true
    add_index :contacts, [ :address_book_id, :resource_name ], unique: true
    add_index :contacts, [ :address_book_id, :sort_key ]
  end
end
