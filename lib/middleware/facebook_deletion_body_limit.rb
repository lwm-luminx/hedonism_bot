require "stringio"

module Middleware
  # Limit the callback body before Rails parses/logs parameters (including chunked requests).
  class FacebookDeletionBodyLimit
    MAX_BYTES = 32_768

    def initialize(app)
      @app = app
    end

    def call(env)
      if env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == "/callbacks/facebook/data-deletion"
        body = (env["rack.input"]&.read(MAX_BYTES + 1) || "")
        if body.bytesize > MAX_BYTES
          return [ 413, { "content-type" => "application/json", "cache-control" => "no-store" }, [ '{"error":"request_too_large"}' ] ]
        end
        env["rack.input"] = StringIO.new(body)
      end
      @app.call(env)
    end
  end
end
