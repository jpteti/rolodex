# CardDAV clients authenticate every request with HTTP Basic auth and an app password.
module CarddavAuthentication
  extend ActiveSupport::Concern

  REALM = "Rolodex CardDAV".freeze

  included do
    before_action :require_https
    before_action :authenticate_app_password
  end

  private
    def require_https
      if Rails.configuration.x.carddav_require_https && !request.ssl?
        render plain: "CardDAV requires HTTPS.\n", status: :forbidden
      end
    end

    def authenticate_app_password
      app_password = authenticate_with_http_basic { |username, secret| AppPassword.authenticate(username, secret) }

      if app_password
        app_password.touch_last_used
        @current_user = app_password.user
      else
        request_http_basic_authentication(REALM, "Valid app password required.\n")
      end
    end

    def current_user
      @current_user
    end
end
