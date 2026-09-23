class CreateGroupMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.string :contact_uid, null: false

      t.timestamps
    end
    add_index :group_memberships, [ :group_id, :contact_uid ], unique: true
    add_index :group_memberships, :contact_uid
  end
end
