require "rails_helper"

RSpec.describe Sankhya::AuditLog, type: :service do
  let(:correlation_id) { "aaaa1111-bbbb-2222-cccc-333333333333" }

  describe ".call" do
    it "retorna Result com success? true" do
      result = described_class.call(
        operation: "notas_fiscais",
        correlation_id: correlation_id,
        request_payload: { foo: "bar" }
      )
      expect(result.success?).to be(true)
      expect(result.payload[:correlation_id]).to eq(correlation_id)
    end

    it "loga com tag Sankhya e correlation_id" do
      log_io = StringIO.new
      logger = ActiveSupport::TaggedLogging.new(Logger.new(log_io))
      allow(Rails).to receive(:logger).and_return(logger)

      described_class.call(
        operation: "registrar_adiantamento",
        correlation_id: correlation_id,
        request_payload: { codprojeto: "PDI-1" }
      )

      output = log_io.string
      expect(output).to include("[Sankhya]")
      expect(output).to include("[#{correlation_id}]")
      expect(output).to include("registrar_adiantamento")
    end

    it "registra status e erro quando fornecidos" do
      log_io = StringIO.new
      logger = ActiveSupport::TaggedLogging.new(Logger.new(log_io))
      allow(Rails).to receive(:logger).and_return(logger)

      described_class.call(
        operation: "notas_fiscais",
        correlation_id: correlation_id,
        response_status: 500,
        error: "timeout"
      )

      output = log_io.string
      expect(output).to include("500")
      expect(output).to include("timeout")
    end

    it "aceita kwargs opcionais sem explodir" do
      expect {
        described_class.call(operation: "ping", correlation_id: correlation_id)
      }.not_to raise_error
    end
  end
end
