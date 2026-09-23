# Sets which groups a contact belongs to, from the checkboxes on the contact page.
class ContactGroupsController < ApplicationController
  def update
    contact = Current.user.address_book.contacts.find(params[:contact_id])
    chosen = Array(params[:group_ids]).map(&:to_s)

    Group.transaction do
      Current.user.address_book.groups.each do |group|
        chosen.include?(group.id.to_s) ? group.add_member(contact.uid) : group.remove_member(contact.uid)
      end
    end
    redirect_to contact, notice: "Groups updated."
  end
end
