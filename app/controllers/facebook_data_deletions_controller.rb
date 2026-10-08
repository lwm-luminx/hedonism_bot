class FacebookDataDeletionsController < ActionController::Base
  skip_forgery_protection only: :create
  before_action :privacy_headers
  layout false

  def create
    origin = ENV.fetch("DATA_DELETION_PUBLIC_ORIGIN", "")
    uri = URI.parse(origin)
    unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? &&
           uri.query.nil? && uri.fragment.nil? && [ "", "/" ].include?(uri.path)
      return render json: { error: "service_unavailable" }, status: :service_unavailable
    end
    return invalid_request if request.content_length.to_i > Facebook::SignedRequestVerifier::MAX_BYTES * 2
    payload = Facebook::SignedRequestVerifier.call(params[:signed_request])
    receipt = DataDeletionRequest.accept!(payload, params[:signed_request])
    # The receipt itself is the durable outbox. The periodic dispatcher retries missed enqueues.
    begin
      FacebookDataDeletionJob.perform_later(receipt.id) unless receipt.status == "completed"
    rescue StandardError
      Rails.logger.error("Facebook deletion enqueue failed receipt=#{receipt.id}")
    end
    render json: { url: "#{origin.chomp('/')}/privacy/deletion/#{receipt.confirmation_code}",
                   confirmation_code: receipt.confirmation_code }
  rescue Facebook::SignedRequestVerifier::InvalidRequest
    invalid_request
  rescue Facebook::SignedRequestVerifier::ConfigurationError, URI::InvalidURIError, ActiveRecord::ActiveRecordError
    render json: { error: "service_unavailable" }, status: :service_unavailable
  end

  def show
    code = params[:confirmation_code]
    return head :not_found unless code.is_a?(String) && code.match?(/\A[0-9a-f]{32}\z/)
    @receipt = DataDeletionRequest.find_by(confirmation_code: code)
    return head :not_found unless @receipt
    respond_to do |format|
      format.html
      format.json do
        render json: { confirmation_code: @receipt.confirmation_code, status: @receipt.public_status,
                       requested_at: @receipt.created_at, completed_at: @receipt.completed_at }
      end
    end
  end

  private

  def invalid_request
    render json: { error: "invalid_signed_request" }, status: :bad_request
  end

  def privacy_headers
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    response.headers["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'"
  end
end
