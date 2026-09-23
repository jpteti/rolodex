class PasskeysController < ApplicationController
  include PasskeyCeremony

  def index
    @passkeys = Current.user.passkeys.order(:created_at)
  end

  def options
    render json: registration_options_for(Current.user)
  end

  def create
    passkey = verified_passkey_for(Current.user, name: params[:name])

    if passkey&.save
      flash[:notice] = "Passkey added."
      render json: { redirect_to: passkeys_url }
    else
      render json: { error: "The passkey could not be registered." }, status: :unprocessable_content
    end
  end

  def destroy
    passkey = Current.user.passkeys.find(params[:id])

    if passkey.last?
      redirect_to passkeys_path, alert: "You cannot remove your only passkey."
    else
      passkey.destroy!
      redirect_to passkeys_path, notice: "Passkey removed."
    end
  end
end
