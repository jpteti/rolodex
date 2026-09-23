# Contacts deleted on a device land in the Trash until restored or permanently deleted.
class TrashesController < ApplicationController
  def index
    @contacts = Current.user.address_book.contacts.trashed.order(trashed_at: :desc)
  end

  # Restores a trashed contact.
  def destroy
    contact = Current.user.address_book.contacts.trashed.find(params[:contact_id])
    contact.restore!
    redirect_to contact, notice: "Restored. #{contact.display_name} will return to your devices at their next refresh."
  end
end
