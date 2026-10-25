require "net/http"

module AudienceKit
  # Reads AudienceKit with Lumière's platform service token (AUDIENCEKIT_SERVICE_TOKEN, an `akst_…` minted with
  # `rake service_token:create PLATFORM=1` on AudienceKit; never committed). The token is exchanged for a short-lived
  # JWT at POST /v1/token/service, kept in memory until shortly before it expires.
  #
  # AudienceKit decides what a photographer may see: the venues and events of the audiences that connected them, in
  # the metros their grant allows. Photos still reach AudienceKit only by its pull over the photography contract.
  class Client
    class Error < StandardError; end
    class NotConfigured < Error; end

    DEFAULT_URL = "https://api.audiencekit.com"
    TIMEOUT = 10
    REFRESH_BEFORE = 5.minutes

    @lock = Mutex.new
    @jwt = nil

    class << self
      attr_accessor :jwt

      def configured?
        token.present?
      end

      def token
        ENV["AUDIENCEKIT_SERVICE_TOKEN"].presence
      end

      def base_url
        ENV.fetch("AUDIENCEKIT_API_URL", DEFAULT_URL).delete_suffix("/")
      end

      # A current JWT, exchanging the service token for a new one when it is missing or about to expire.
      def bearer
        @lock.synchronize do
          self.jwt = nil if jwt && jwt[:expires_at] < REFRESH_BEFORE.from_now
          self.jwt ||= exchange
          jwt[:token]
        end
      end

      def reset!
        @lock.synchronize { self.jwt = nil }
      end

      private

      def exchange
        raise NotConfigured, "AudienceKit isn't connected: set AUDIENCEKIT_SERVICE_TOKEN" unless configured?

        body = new.send(:request, Net::HTTP::Post, "/v1/token/service", form: { service_token: token })
        expires_at = Time.iso8601(body.fetch("expiresAt"))
        { token: body.fetch("token"), expires_at: expires_at }
      rescue KeyError, ArgumentError, TypeError
        raise Error, "AudienceKit answered the token exchange without a token"
      end
    end

    # The venues and events `photographer_id` may link albums to, per connected audience (AudienceKit's
    # PhotographerCatalog): { "audiences" => [{ "id", "name", "events" => [...], "venues" => [...] }] }.
    def catalog(photographer_id, audience_id: nil, from: nil, to: nil, query: nil, latitude: nil, longitude: nil,
                event_id: nil, venue_id: nil)
      params = { audience_id: audience_id, from: from&.utc&.iso8601, to: to&.utc&.iso8601, query: query.presence,
                 latitude: latitude, longitude: longitude, event_id: event_id, venue_id: venue_id }.compact
      path = "/v1/platform/photographers/#{ERB::Util.url_encode(photographer_id)}/catalog"
      result = request(Net::HTTP::Get, path, params: params, auth: true)
      raise Error, "AudienceKit sent a malformed catalog" unless result.is_a?(Hash) && result["audiences"].is_a?(Array)

      result
    end

    private

    def request(verb, path, params: {}, form: nil, auth: false, retried: false)
      uri = URI("#{self.class.base_url}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      outgoing = verb.new(uri, "Accept" => "application/json")
      outgoing["Authorization"] = "Bearer #{self.class.bearer}" if auth
      outgoing.set_form_data(form) if form
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: TIMEOUT,
                                                     read_timeout: TIMEOUT) { |http| http.request(outgoing) }
      if auth && response.code == "401" && !retried
        self.class.reset!
        return request(verb, path, params: params, form: form, auth: auth, retried: true)
      end
      raise Error, "AudienceKit answered #{response.code}: #{message(response)}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, "AudienceKit sent something that isn't JSON"
    rescue IOError, SystemCallError, Timeout::Error, SocketError, OpenSSL::SSL::SSLError => e
      raise Error, "AudienceKit couldn't be reached: #{e.message}"
    end

    def message(response)
      JSON.parse(response.body.to_s)["message"].to_s.truncate(200)
    rescue JSON::ParserError
      response.message
    end
  end
end
