namespace :rolodex do
  desc "Create the user if missing and print a single-use passkey setup URL. Set ROLODEX_USER to pick the username (default: owner)."
  task setup_link: :environment do
    user = User.find_or_create_by!(username: ENV.fetch("ROLODEX_USER", "owner"))
    link = SetupLink.issue(user)
    origin = URI.parse(Rails.application.config.x.app_origin)
    url = Rails.application.routes.url_helpers.setup_url(link.token, protocol: origin.scheme, host: origin.host, port: origin.port)

    puts "Passkey setup link for #{user.username}. It works once and expires at #{link.expires_at.utc.strftime('%H:%M UTC')}:"
    puts url
  end
end
