class CreateSyncChanges < ActiveRecord::Migration[8.1]
  def up
    create_table :sync_changes do |t|
      t.references :address_book, null: false, foreign_key: true
      t.string :resource_name, null: false
      t.boolean :removed, null: false, default: false

      t.timestamps
    end
    add_index :sync_changes, [ :address_book_id, :id ]

    # Record every contact devices can already see, so a token issued now covers them.
    execute <<~SQL
      INSERT INTO sync_changes (address_book_id, resource_name, removed, created_at, updated_at)
      SELECT address_book_id, resource_name, FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM contacts WHERE archived_at IS NULL AND trashed_at IS NULL ORDER BY id
    SQL
  end

  def down
    drop_table :sync_changes
  end
end
