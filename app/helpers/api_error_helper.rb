module ApiErrorHelper
  private

  def error_response_for(exception)
    case exception
    when ActiveRecord::RecordInvalid
      record_errors(exception.record)
    when ActiveRecord::RecordNotFound
      single_error(status: :not_found,   code: "not_found",   detail: exception.message)
    when ActionController::ParameterMissing
      single_error(status: :bad_request, code: "bad_request", detail: exception.message)
    end
  end

  def record_errors(record)
    errors = record.errors.map do |error|
      {
        status: "422",
        code: "validation_error",
        source: { pointer: "/data/attributes/#{error.attribute}" },
        title: "Validation failed",
        detail: error.full_message
      }
    end
    { json: { errors: errors }, status: :unprocessable_entity }
  end

  def single_error(status:, code:, detail:, source: nil)
    body = { status: Rack::Utils.status_code(status).to_s, code: code, detail: detail }
    body[:source] = source if source
    { json: { errors: [body] }, status: status }
  end
end
