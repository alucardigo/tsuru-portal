module Sankhya
  class AuditLog
    Result = Struct.new(:success?, :payload, keyword_init: true)

    def self.call(operation:, correlation_id:, request_payload: nil, response_status: nil, response_body: nil, error: nil)
      Rails.logger.tagged("Sankhya", correlation_id) do
        Rails.logger.info({
          operation: operation,
          status: response_status,
          error: error,
          ts: Time.current.iso8601
        }.to_json)
      end
      Result.new(success?: true, payload: { correlation_id: correlation_id })
    end
  end
end
