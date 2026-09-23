class AddHasPhotoToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :has_photo, :boolean, null: false, default: false
  end
end
