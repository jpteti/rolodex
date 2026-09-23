# Origins the web UI runs on. A passkey is bound to the host it was registered on, so each origin
# needs its own passkey. Set APP_ORIGIN to one origin, or several separated by commas.
# Development allows localhost and https://rolodex.test, where puma-dev serves the app (see README).
Rails.application.config.x.app_origins = ENV.fetch("APP_ORIGIN") {
  case Rails.env
  when "test" then "http://www.example.com"
  when "development" then "http://localhost:3000,https://rolodex.test"
  else "http://localhost:3000"
  end
}.split(",").map(&:strip)

Rails.application.config.x.app_origin = Rails.application.config.x.app_origins.first

# Defaults for the first origin. Controllers build a relying party for the origin of each request.
WebAuthn.configure do |config|
  config.allowed_origins = [ Rails.application.config.x.app_origin ]
  config.rp_name = "Rolodex"
  config.rp_id = URI.parse(Rails.application.config.x.app_origin).host
end
