class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ show edit update destroy ]

  def index
    @query = params[:q].to_s.strip
    @include_archived = params[:archived] == "1"
    scope = @include_archived ? address_book.contacts.untrashed : address_book.contacts.active
    @contacts = scope.search(@query).sorted
  end

  def show
    @editor = ContactEditor.for(@contact)
  end

  def new
    @editor = ContactEditor.blank(uid: SecureRandom.uuid.upcase)
  end

  def create
    uid = SecureRandom.uuid.upcase
    @editor = ContactEditor.blank(uid: uid).assign(contact_params)

    if @editor.valid?
      contact = address_book.contacts.create!(uid: uid, resource_name: "#{uid}.vcf", vcard: @editor.to_vcard)
      redirect_to contact, notice: "Contact created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @editor = ContactEditor.for(@contact)
  end

  def update
    @editor = ContactEditor.for(@contact).assign(contact_params)

    if @editor.valid? && @contact.update(vcard: @editor.to_vcard(@contact.vcard))
      redirect_to @contact, notice: "Contact saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deleting on the web matches deleting on a device: the contact moves to the Trash.
  def destroy
    @contact.trash!
    redirect_to contacts_path, notice: "#{@contact.display_name} moved to the Trash."
  end

  private
    def address_book
      Current.user.address_book
    end

    def set_contact
      @contact = address_book.contacts.find(params[:id])
    end

    def contact_params
      row = %i[ ref label value ]
      params.expect(contact: [
        *ContactEditor::SINGLE_FIELDS,
        emails: [ row ], phones: [ row ], urls: [ row ],
        addresses: [ [ :ref, :label, *ContactEditor::ADDRESS_PARTS ] ]
      ])
    end
end
