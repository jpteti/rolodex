# Base for CardDAV endpoints. Skips the web UI's session and CSRF handling; auth is Basic with app passwords.
class Carddav::BaseController < ActionController::Base
  include CarddavAuthentication

  skip_forgery_protection
end
