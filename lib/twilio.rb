module Twilio
  def send_admin_text_message(text)
    client = Twilio::REST::Client.new "AC5f75bb86a003e5cda83d9d7514de864b", Rails.application.secrets[:twilio_key]

    client.messages.create(
      from: "+14063154776",
      to: "+12069133215",
      body: text
    )
  rescue StandardError => e
    Rails.logger.error e
  end
end
