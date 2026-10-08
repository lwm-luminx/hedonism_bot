# Errors reported by the gallery's frontend: uncaught exceptions, unhandled promise rejections and React error
# boundary catches. Each report is written to the log as one `[client_error]` line, so they show in `heroku logs`
# next to the app's own errors.
#
#   POST /client_errors   {"message": "…", "stack": "…", "url": "…", "kind": "error", …}
#
# Accepts a text/plain body so the browser can send it with navigator.sendBeacon. Fields are truncated and each IP
# is limited to RATE_LIMIT reports a minute; the response is always 204 so the frontend never retries.
class ClientErrorsController < ApplicationController
  # Reports only write a log line, and beacons can't carry a CSRF token.
  skip_forgery_protection

  FIELDS = { kind: 40, release: 80, message: 1_000, stack: 4_000, component_stack: 4_000,
             url: 500, source: 500, line: 10, column: 10 }.freeze
  MAX_BODY = 16.kilobytes
  RATE_LIMIT = 30

  def create
    report = parse_report
    log(report) if report && !throttled?
    head :no_content
  end

  private

  def parse_report
    body = request.raw_post.to_s
    return if body.bytesize > MAX_BODY

    data = JSON.parse(body)
    return unless data.is_a?(Hash)

    FIELDS.each_with_object({}) do |(field, limit), report|
      value = data[field.to_s]
      report[field] = value.to_s.scrub.truncate(limit) unless value.nil? || value.to_s.empty?
    end.presence
  rescue JSON::ParserError
    nil
  end

  def throttled?
    key = "client_errors:#{request.remote_ip}:#{Time.current.to_i / 60}"
    count = Rails.cache.increment(key, 1, expires_in: 2.minutes)
    count.nil? ? (Rails.cache.write(key, 1, expires_in: 2.minutes) && false) : count > RATE_LIMIT
  end

  def log(report)
    report[:photographer] = photographer.subdomain
    report[:user_id] = current_user.id if current_user
    report[:user_agent] = request.user_agent.to_s.truncate(300) if request.user_agent.present?
    logger.warn("[client_error] #{report.to_json}")
  end
end
