namespace :rolodex do
  desc "Create the user if missing and print a single-use passkey setup URL. Set ROLODEX_USER to pick the username (default: owner)."
  task setup_link: :environment do
    user = User.find_or_create_by!(username: ENV.fetch("ROLODEX_USER", "owner"))
    link = SetupLink.issue(user)
    urls = Rails.application.config.x.app_origins.map do |origin|
      uri = URI.parse(origin)
      Rails.application.routes.url_helpers.setup_url(link.token, protocol: uri.scheme, host: uri.host, port: uri.port)
    end

    puts "Passkey setup link for #{user.username}. It works once and expires at #{link.expires_at.utc.strftime('%H:%M UTC')}."
    puts "A passkey works only on the host where you register it. Open the link for that host:" if urls.many?
    puts urls
  end
end
