require "rails_helper"

RSpec.describe Sankhya::Service, type: :service do
  let(:fake_token) { "fake-token-xyz" }
  let(:mock_client) { instance_double(Sankhya::Client, token: fake_token) }
  let(:service) { described_class.new(client: mock_client) }

  describe "correlation_id e audit_log" do
    # Formato REAL do gateway (confirmado em produção 03/07/2026): cada linha
    # tem chaves posicionais f0,f1,f2... (na ordem do fieldset enviado), valor
    # embrulhado em {"$" => valor}. NUNOTA=f0, NUMNOTA=f1, DTNEG=f2, VLRNOTA=f3,
    # CODPARC=f4, NOMEPARC=f5 (ordem de Sankhya::Service::NOTAS_FISCAIS_CAMPOS).
    let(:sankhya_nf_response) do
      {
        "responseBody" => {
          "entities" => {
            "entity" => [
              {
                "f0" => { "$" => "1001" },
                "f1" => { "$" => "42" },
                "f2" => { "$" => "03/07/2026" },
                "f3" => { "$" => "1500.00" },
                "f4" => { "$" => "6" },
                "f5" => { "$" => "BEL DISTRIBUIDOR DE LUBRIFICANTES LTDA" }
              }
            ]
          }
        }
      }.to_json
    end

    before do
      stub_request(:post, /api\.sankhya\.com\.br.*service\.sbr/)
        .to_return(status: 200, body: sankhya_nf_response,
                   headers: { "Content-Type" => "application/json" })
    end

    it "gera correlation_id único por chamada" do
      uuid_1 = "11111111-1111-1111-1111-111111111111"
      uuid_2 = "22222222-2222-2222-2222-222222222222"
      allow(SecureRandom).to receive(:uuid).and_return(uuid_1, uuid_2)

      service.notas_fiscais(codparc: 1)
      service.notas_fiscais(codparc: 2)

      expect(WebMock).to have_requested(:post, /api\.sankhya\.com\.br/)
        .with(headers: { "X-Correlation-Id" => uuid_1 })
      expect(WebMock).to have_requested(:post, /api\.sankhya\.com\.br/)
        .with(headers: { "X-Correlation-Id" => uuid_2 })
    end

    it "envia header X-Correlation-Id na requisição" do
      service.notas_fiscais(codparc: 123)
      expect(WebMock).to have_requested(:post, /api\.sankhya\.com\.br/)
        .with(headers: { "X-Correlation-Id" => /[0-9a-f-]{36}/ })
    end

    it "chama Sankhya::AuditLog antes e depois do POST" do
      expect(Sankhya::AuditLog).to receive(:call)
        .with(hash_including(operation: "notas_fiscais", correlation_id: kind_of(String)))
        .at_least(:twice)
        .and_call_original

      service.notas_fiscais(codparc: 1)
    end

    it "registra erro no AuditLog quando POST falha" do
      stub_request(:post, /api\.sankhya\.com\.br.*service\.sbr/)
        .to_return(status: 500, body: "boom")

      audit_calls = []
      allow(Sankhya::AuditLog).to receive(:call) do |**kwargs|
        audit_calls << kwargs
        Sankhya::AuditLog::Result.new(success?: true, payload: { correlation_id: kwargs[:correlation_id] })
      end

      expect { service.notas_fiscais(codparc: 1) }.to raise_error(Faraday::Error)
      expect(audit_calls.last[:error]).to be_a(String)
    end
  end

  describe "#notas_fiscais (compatibilidade funcional)" do
    let(:sankhya_nf_response) do
      {
        "responseBody" => {
          "entities" => {
            "entity" => [
              {
                "f0" => { "$" => "1001" },
                "f1" => { "$" => "42" },
                "f2" => { "$" => "03/07/2026" },
                "f3" => { "$" => "1500.00" },
                "f4" => { "$" => "6" },
                "f5" => { "$" => "BEL DISTRIBUIDOR DE LUBRIFICANTES LTDA" }
              }
            ]
          }
        }
      }.to_json
    end

    before do
      stub_request(:post, /api\.sankhya\.com\.br.*service\.sbr/)
        .with(headers: { "Authorization" => "Bearer #{fake_token}" })
        .to_return(status: 200, body: sankhya_nf_response,
                   headers: { "Content-Type" => "application/json" })
    end

    it "remapeia as linhas posicionais (f0,f1...) para o nome real do campo" do
      result = service.notas_fiscais(codparc: 123)
      expect(result).to be_an(Array)
      expect(result.first).to eq(
        "NUNOTA" => "1001", "NUMNOTA" => "42", "DTNEG" => "03/07/2026",
        "VLRNOTA" => "1500.00", "CODPARC" => "6", "NOMEPARC" => "BEL DISTRIBUIDOR DE LUBRIFICANTES LTDA"
      )
    end
  end

  describe "#registrar_adiantamento (compatibilidade funcional)" do
    let(:sankhya_save_response) do
      { "status" => "1", "statusMessage" => "OK", "responseBody" => {} }.to_json
    end

    before do
      stub_request(:post, /api\.sankhya\.com\.br.*service\.sbr/)
        .to_return(status: 200, body: sankhya_save_response,
                   headers: { "Content-Type" => "application/json" })
    end

    it "retorna hash com status da operacao" do
      result = service.registrar_adiantamento(
        codprojeto: "PDI-2025-001", valor: 5000.0, descricao: "Adiantamento"
      )
      expect(result["status"]).to eq("1")
    end
  end
end
