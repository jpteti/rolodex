class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.references :address_book, null: false, foreign_key: true
      t.string :uid, null: false
      t.string :resource_name, null: false
      t.text :vcard, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :groups, [ :address_book_id, :uid ], unique: true
    add_index :groups, [ :address_book_id, :resource_name ], unique: true
  end
end
