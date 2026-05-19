require "rails_helper"

RSpec.describe SankhyaService, type: :service do
  let(:fake_token) { "fake-token-xyz" }
  let(:mock_client) { instance_double(SankhyaClient, token: fake_token) }
  let(:service) { described_class.new(client: mock_client) }

  describe "#notas_fiscais" do
    let(:sankhya_nf_response) do
      {
        "responseBody" => {
          "entities" => {
            "entity" => [
              { "f" => [
                { "$" => "1001", "_" => "NUNOTA" },
                { "$" => "42", "_" => "NUMNOTA" },
                { "$" => "15/05/2025", "_" => "DTNEG" },
                { "$" => "12500.00", "_" => "VLRNOTA" }
              ] }
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

    it "retorna array de registros de notas fiscais" do
      result = service.notas_fiscais(codparc: 123)
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
    end

    it "envia o codparc na query" do
      service.notas_fiscais(codparc: 456)
      expect(WebMock).to have_requested(:post, /api\.sankhya\.com\.br/)
        .with(body: /456/)
    end

    it "inclui o token Bearer no header" do
      service.notas_fiscais(codparc: 1)
      expect(WebMock).to have_requested(:post, /api\.sankhya\.com\.br/)
        .with(headers: { "Authorization" => "Bearer #{fake_token}" })
    end
  end

  describe "#registrar_adiantamento" do
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
        codprojeto: "PDI-2025-001",
        valor: 5000.0,
        descricao: "Adiantamento pesquisador"
      )
      expect(result).to be_a(Hash)
      expect(result["status"]).to eq("1")
    end

    it "inclui codprojeto no payload" do
      service.registrar_adiantamento(
        codprojeto: "PDI-TEST", valor: 1000.0, descricao: "Teste"
      )
      expect(WebMock).to have_requested(:post, /api\.sankhya\.com\.br/)
        .with(body: /PDI-TEST/)
    end
  end

  describe "error handling" do
    it "propaga Faraday::Error quando API retorna 5xx" do
      stub_request(:post, /api\.sankhya\.com\.br.*service\.sbr/)
        .to_return(status: 500, body: "Internal Server Error")
      expect { service.notas_fiscais(codparc: 1) }.to raise_error(Faraday::Error)
    end
  end
end
