class AppPasswordsController < ApplicationController
  def index
    @app_passwords = Current.user.app_passwords.order(:created_at)
  end

  def create
    @app_password = AppPassword.generate(Current.user, name: params.expect(app_password: [ :name ])[:name])

    if @app_password.persisted?
      render :created
    else
      @app_passwords = Current.user.app_passwords.order(:created_at)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    Current.user.app_passwords.find(params[:id]).destroy!
    redirect_to app_passwords_path, notice: "App password revoked."
  end
end
