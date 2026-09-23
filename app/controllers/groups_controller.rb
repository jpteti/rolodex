class GroupsController < ApplicationController
  def index
    @groups = Current.user.address_book.groups.sorted.includes(:memberships)
    @active_uids = Current.user.address_book.contacts.active.pluck(:uid).to_set
  end
end
