# Shared steps for WebAuthn registration and authentication. The browser fetches options,
# runs the ceremony, and posts the resulting credential back as JSON.
module PasskeyCeremony
  extend ActiveSupport::Concern

  private
    def registration_options_for(user)
      options = WebAuthn::Credential.options_for_create(
        user: { id: user.webauthn_id, name: user.username, display_name: user.username },
        exclude: user.passkeys.pluck(:external_id),
        authenticator_selection: { resident_key: "required", user_verification: "preferred" }
      )
      session[:webauthn_challenge] = options.challenge
      options
    end

    def authentication_options
      options = WebAuthn::Credential.options_for_get(user_verification: "preferred")
      session[:webauthn_challenge] = options.challenge
      options
    end

    # Verifies a registration response and returns an unsaved passkey, or nil when verification fails.
    def verified_passkey_for(user, name:)
      credential = WebAuthn::Credential.from_create(credential_params)
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
      credential = WebAuthn::Credential.from_get(credential_params)
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
