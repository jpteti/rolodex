# Archive keeps a contact in Rolodex but removes it from every device.
class ArchivesController < ApplicationController
  before_action :set_contact, only: %i[ create destroy ]

  def index
    @contacts = Current.user.address_book.contacts.archived.sorted
  end

  def create
    @contact.archive!
    redirect_to @contact, notice: "Archived. #{@contact.display_name} will disappear from your devices at their next refresh."
  end

  def destroy
    @contact.unarchive!
    redirect_to @contact, notice: "Unarchived. #{@contact.display_name} will return to your devices at their next refresh."
  end

  private
    def set_contact
      @contact = Current.user.address_book.contacts.find(params[:contact_id])
    end
end
