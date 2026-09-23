class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :address_book, null: false, foreign_key: true
      t.string :filename, null: false
      t.text :source, null: false
      t.string :status, null: false, default: "pending"
      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.text :failures, null: false, default: "[]"
      t.datetime :finished_at

      t.timestamps
    end
  end
end
