class GroupsController < ApplicationController
  before_action :set_group, only: %i[ edit update destroy ]

  def index
    @groups = groups.sorted.includes(:memberships)
    @active_uids = Current.user.address_book.contacts.active.pluck(:uid).to_set
    @group = Group.new
  end

  def create
    @group = Group.create_named(Current.user.address_book, params.expect(group: [ :name ])[:name])

    if @group.persisted?
      redirect_to groups_path, notice: "Group “#{@group.name}” created."
    else
      @groups = groups.sorted.includes(:memberships)
      @active_uids = Current.user.address_book.contacts.active.pluck(:uid).to_set
      render :index, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @group.rename(params.expect(group: [ :name ])[:name])
      redirect_to groups_path, notice: "Group renamed to “#{@group.name}”."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deleting a group leaves its contacts in place.
  def destroy
    @group.destroy!
    redirect_to groups_path, notice: "Group “#{@group.name}” deleted."
  end

  private
    def groups
      Current.user.address_book.groups
    end

    def set_group
      @group = groups.find(params[:id])
    end
end
