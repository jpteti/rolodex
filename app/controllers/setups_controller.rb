# Registers a passkey from a single-use setup link. Handles first setup and recovery.
class SetupsController < ApplicationController
  include PasskeyCeremony

  allow_unauthenticated_access
  before_action :set_setup_link

  def show
  end

  def options
    render json: registration_options_for(@setup_link.user)
  end

  def create
    passkey = verified_passkey_for(@setup_link.user, name: params[:name])

    if passkey && @setup_link.redeem!
      passkey.save!
      
      session_creation_result = SessionCreator.new.create_session(user: @setup_link.user, request:)
      
      if session_creation_result.created?
        remember_session(session_creation_result.session)
        # start_new_session_for @setup_link.user
        render json: { redirect_to: root_url }
      else
        render json: { error: "An unknown error occurred." }, status: :unprocessable_content
      end
    else
      render json: { error: "The passkey could not be registered." }, status: :unprocessable_content
    end
  end

  private
    def set_setup_link
      @setup_link = SetupLink.find_usable(params[:token])
      return if @setup_link

      respond_to do |format|
        format.html { render :invalid, status: :not_found }
        format.json { render json: { error: "This setup link has expired or was already used." }, status: :not_found }
      end
    end
end
