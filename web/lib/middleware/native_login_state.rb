module Middleware
  # Chip and Chip for Mac sign in through ASWebAuthenticationSession. iOS can drop the sheet's session
  # cookie while Facebook is on screen (switching to the Facebook app relaunches the web view), so the
  # Facebook callback arrived with no OmniAuth state or native login and ended on a 404. For native
  # logins the OAuth state is a signed copy of that context, and the callback restores it when the
  # cookie is gone. The PKCE challenge inside still binds the resulting grant to the app that asked.
  class NativeLoginState
    CALLBACK_PATH = "/auth/facebook/callback"
    PURPOSE = :facebook_oauth_state

    # OAuth state for OmniAuth's Facebook request phase: signed native context, else a random value.
    def self.generate(env)
      login = env["rack.session"]&.[]("native_login")
      return SecureRandom.hex(24) unless login

      verifier.generate({ "native_login" => login, "nonce" => SecureRandom.hex(16) }, purpose: PURPOSE, expires_in: 10.minutes)
    end

    def self.verifier
      Rails.application.message_verifier(:native_login_state)
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      restore(env) if env["REQUEST_METHOD"] == "GET" && env["PATH_INFO"] == CALLBACK_PATH
      @app.call(env)
    end

    private

    def restore(env)
      session = env["rack.session"]
      return if session.nil? || session["omniauth.state"].present?

      state = Rack::Request.new(env).GET["state"].to_s
      payload = self.class.verifier.verified(state, purpose: PURPOSE) if state.present?
      return unless payload.is_a?(Hash) && payload["native_login"].is_a?(Hash)

      session["omniauth.state"] = state
      session["native_login"] = payload["native_login"]
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end
end
