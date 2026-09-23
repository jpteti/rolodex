class AddArchivedAtToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :archived_at, :datetime
    add_index :contacts, :archived_at
  end
end
