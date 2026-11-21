# frozen_string_literal: true

# Sends a sign-in that ran on api.<SERVICE_DOMAIN> back to the photographer's host that started it.
# The ticket carries the result (a user ID or an error) and the nonce the tenant host keeps in its own
# session, so only the browser that began sign-in can redeem it (see AuthBridgesController#complete).
module TenantAuthReturn
  private

  def redirect_to_tenant(context, **result)
    ticket = Rails.application.message_verifier(:tenant_auth).generate(context.merge(result.stringify_keys),
                                                                     purpose: :auth_return, expires_in: 1.minute)
    redirect_to "https://#{context['host']}/auth/return?#{ { ticket: ticket }.to_query }", allow_other_host: true
  end
end
