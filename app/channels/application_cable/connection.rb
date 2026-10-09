module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :service_account

    def connect
      @credential = request.headers["Authorization"].to_s[/\ABearer (.+)\z/, 1]
      self.service_account = ServiceAccount.authenticate(@credential)
      reject_unauthorized_connection unless service_account
    end

    def authorized?
      ServiceAccount.authenticate(@credential)&.id == service_account.id
    end
  end
end
