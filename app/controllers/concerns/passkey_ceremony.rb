# Shared steps for WebAuthn registration and authentication. The browser fetches options,
# runs the ceremony, and posts the resulting credential back as JSON.
module PasskeyCeremony
  extend ActiveSupport::Concern

  class UnknownOrigin < StandardError; end

  included do
    rescue_from UnknownOrigin do
      render json: { error: "Passkeys are not set up for #{request.base_url}. Add it to APP_ORIGIN." }, status: :unprocessable_content
    end
  end

  private
    # A relying party for the origin serving this request, so passkeys work on every configured origin.
    def relying_party
      @relying_party ||= begin
        raise UnknownOrigin unless Rails.configuration.x.app_origins.include?(request.base_url)

        WebAuthn::RelyingParty.new(allowed_origins: [ request.base_url ], id: request.host, name: "Rolodex")
      end
    end

    def registration_options_for(user)
      options = WebAuthn::Credential.options_for_create(
        user: { id: user.webauthn_id, name: user.username, display_name: user.username },
        exclude: user.passkeys.pluck(:external_id),
        authenticator_selection: { resident_key: "required", user_verification: "preferred" },
        relying_party: relying_party
      )
      session[:webauthn_challenge] = options.challenge
      options
    end

    def authentication_options
      options = WebAuthn::Credential.options_for_get(user_verification: "preferred", relying_party: relying_party)
      session[:webauthn_challenge] = options.challenge
      options
    end

    # Verifies a registration response and returns an unsaved passkey, or nil when verification fails.
    def verified_passkey_for(user, name:)
      credential = WebAuthn::Credential.from_create(credential_params, relying_party: relying_party)
      credential.verify(session.delete(:webauthn_challenge))

      user.passkeys.new(
        external_id: credential.id,
        public_key: credential.public_key,
        sign_count: credential.sign_count,
        name: name.presence || "Passkey"
      )
    rescue WebAuthn::Error, KeyError, JSON::ParserError
      nil
    end

    # Verifies an authentication response and returns the matching passkey, or nil.
    def verified_passkey_from_assertion
      credential = WebAuthn::Credential.from_get(credential_params, relying_party: relying_party)
      passkey = Passkey.find_by(external_id: credential.id) or return

      credential.verify(session.delete(:webauthn_challenge), public_key: passkey.public_key, sign_count: passkey.sign_count)
      passkey.update!(sign_count: credential.sign_count, last_used_at: Time.current)
      passkey
    rescue WebAuthn::Error, KeyError, JSON::ParserError
      nil
    end

    # The browser posts the credential as JSON; its nested shape is checked by the webauthn gem.
    def credential_params
      JSON.parse(request.raw_post).fetch("credential")
    end
end
