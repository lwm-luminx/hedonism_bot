module Twilio
  def send_admin_text_message(text)
    key = Rails.application.secrets[:twilio_key]
    client = Twilio::REST::Client.new key, Rails.application.secrets[:twilio_key]

    client.messages.create(
      from: "+14063154776",
      to: "+12069133215",
      body: text
    )
  rescue StandardError => e
    Rails.logger.error e
  end
end
