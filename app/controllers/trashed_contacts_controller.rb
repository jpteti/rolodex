# Contacts deleted on a device land in the Trash until restored or permanently deleted.
class TrashedContactsController < ApplicationController
  before_action :set_contact, only: %i[ restore destroy ]

  def index
    @contacts = trashed_contacts.order(trashed_at: :desc)
  end

  def restore
    @contact.restore!
    redirect_to @contact, notice: "Restored. #{@contact.display_name} will return to your devices at their next refresh."
  end

  # Permanent: the contact is removed from the database.
  def destroy
    @contact.destroy!
    redirect_to trashed_contacts_path, notice: "#{@contact.display_name} was permanently deleted."
  end

  def empty
    count = trashed_contacts.destroy_all.size
    redirect_to trashed_contacts_path, notice: "Permanently deleted #{helpers.pluralize(count, 'contact')}."
  end

  private
    def trashed_contacts
      Current.user.address_book.contacts.trashed
    end

    # Only trashed contacts can be restored or permanently deleted.
    def set_contact
      @contact = trashed_contacts.find(params[:id])
    end
end
