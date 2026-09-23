class AddTrashedAtToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :trashed_at, :datetime
    add_index :contacts, :trashed_at
  end
end
