class Carddav::RootController < Carddav::BaseController
  def show
    render plain: "Rolodex CardDAV for #{current_user.username}\n"
  end
end
