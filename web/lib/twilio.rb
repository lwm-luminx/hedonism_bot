module Twilio
  # Texts the admin phone. A no-op unless the twilio-ruby gem and `twilio.sid` / `twilio.token`
  # credentials are present, so it never blocks the caller (e.g. a first Facebook sign-in).
  def self.send_admin_text_message(text)
    sid = Rails.application.credentials.dig(:twilio, :sid)
    token = Rails.application.credentials.dig(:twilio, :token)
    return unless sid && token && defined?(Twilio::REST::Client)

    client = Twilio::REST::Client.new sid, token

    client.messages.create(
      from: "+14063154776",
      to: "+12069133215",
      body: text
    )
  rescue StandardError => e
    Rails.logger.error e
  end
end
