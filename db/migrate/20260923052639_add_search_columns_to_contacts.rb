class AddSearchColumnsToContacts < ActiveRecord::Migration[8.1]
  class MigrationContact < ActiveRecord::Base
    self.table_name = "contacts"
  end

  def up
    add_column :contacts, :search_text, :text, null: false, default: ""
    add_column :contacts, :phone_digits, :text, null: false, default: ""

    MigrationContact.reset_column_information
    MigrationContact.find_each do |contact|
      emails = JSON.parse(contact.emails || "[]")
      phones = JSON.parse(contact.phones || "[]")
      contact.update_columns(
        search_text: [ contact.display_name, contact.given_name, contact.family_name, contact.organization, *emails ].compact.join(" ").downcase,
        phone_digits: phones.map { |phone| phone.gsub(/\D/, "") }.join(" ")
      )
    end
  end

  def down
    remove_column :contacts, :search_text
    remove_column :contacts, :phone_digits
  end
end
