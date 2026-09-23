class SessionsController < ApplicationController
  include PasskeyCeremony

  allow_unauthenticated_access only: %i[ new options create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: "Too many attempts. Try again later." }, status: :too_many_requests }

  def new
    redirect_to root_path if authenticated?
  end

  def options
    render json: authentication_options
  end

  def create
    if (passkey = verified_passkey_from_assertion)
      result = SessionCreator.new.create_session(user: passkey.user, request:)
      
      if result.created?
        remember_session(result.session)
        # start_new_session_for passkey.user
        render json: { redirect_to: after_authentication_url }
      else
        render json: { error: "Unknown error occurred." }, status: :unprocessable_content
      end
    else
      render json: { error: "That passkey was not recognized." }, status: :unprocessable_content
    end
  end

  def destroy
    result = SessionTerminator.new.terminate_session(Current.session)
    
    if result.terminated?
      forget_session
      redirect_to new_session_path, status: :see_other, notice: "Signed out."
    else
      redirect_to root_path, error: "Could not sign you out."
    end
  end
end
