class PhotosController < ApplicationController
  before_action :set_contact

  def show
    photo = @contact.photo or return head(:not_found)

    if stale?(etag: @contact.etag, public: false)
      send_data photo.data, type: photo.content_type, disposition: :inline
    end
  end

  def update
    upload = params.expect(photo: [ :file ])[:file]
    card = ContactPhoto.write(@contact.card, upload)
    @contact.update!(vcard: card.to_s)
    redirect_to edit_contact_path(@contact), notice: "Photo saved."
  rescue ContactPhoto::InvalidImage => error
    redirect_to edit_contact_path(@contact), alert: error.message
  rescue ActionController::ParameterMissing
    redirect_to edit_contact_path(@contact), alert: "Choose a photo to upload."
  end

  def destroy
    card = @contact.card
    ContactPhoto.remove(card)
    @contact.update!(vcard: card.to_s)
    redirect_to edit_contact_path(@contact), notice: "Photo removed."
  end

  private
    def set_contact
      @contact = Current.user.address_book.contacts.find(params[:contact_id])
    end
end
