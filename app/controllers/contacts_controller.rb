class ContactsController < ApplicationController
  before_action :set_contact, only: :show

  def index
    @contacts = address_book.contacts.sorted
  end

  def show
  end

  def new
    @form = ContactForm.new
  end

  def create
    @form = ContactForm.new(contact_params)

    if @form.save(address_book)
      redirect_to @form.contact, notice: "Contact created."
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def address_book
      Current.user.address_book
    end

    def set_contact
      @contact = address_book.contacts.find(params[:id])
    end

    def contact_params
      params.expect(contact_form: [ :given_name, :family_name, :organization, emails: [], phones: [] ])
    end
end
