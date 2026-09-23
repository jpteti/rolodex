# The origin the web UI runs on. Passkeys are bound to its host.
Rails.application.config.x.app_origin = ENV.fetch("APP_ORIGIN") do
  Rails.env.test? ? "http://www.example.com" : "http://localhost:3000"
end

WebAuthn.configure do |config|
  config.allowed_origins = [ Rails.application.config.x.app_origin ]
  config.rp_name = "Rolodex"
  config.rp_id = URI.parse(Rails.application.config.x.app_origin).host
end
