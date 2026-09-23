require "webauthn/fake_client"

module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("session_id")
  end

  def fake_client
    @fake_client ||= WebAuthn::FakeClient.new(Rails.application.config.x.app_origin)
  end

  # Runs a registration ceremony against the given options and submit URLs.
  def register_passkey(options_url:, submit_url:, name: "Test key", client: fake_client)
    post options_url, params: {}, as: :json
    challenge = response.parsed_body["challenge"]
    post submit_url, params: { credential: client.create(challenge: challenge), name: name }, as: :json
  end

  def authenticate_with_passkey(client: fake_client)
    post options_session_url, params: {}, as: :json
    challenge = response.parsed_body["challenge"]
    post session_url, params: { credential: client.get(challenge: challenge) }, as: :json
  end
end
