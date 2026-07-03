require "rails_helper"

RSpec.describe SankhyaService, type: :service do
  let(:fake_token) { "fake-token-xyz" }
  let(:mock_client) { instance_double(SankhyaClient, token: fake_token) }
  let(:service) { described_class.new(client: mock_client) }

  describe "#notas_fiscais" do
    # Formato REAL do gateway (confirmado em produção 03/07/2026): chaves
    # posicionais f0,f1,f2... na ordem do fieldset enviado (ver
    # Sankhya::Service::NOTAS_FISCAIS_CAMPOS), valor embrulhado em {"$" => valor}.
    let(:sankhya_nf_response) do
      {
        "responseBody" => {
          "entities" => {
            "entity" => [
              {
                "f0" => { "$" => "1001" },
                "f1" => { "$" => "42" },
                "f2" => { "$" => "15/05/2025" },
                "f3" => { "$" => "12500.00" },
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

    it "remapeia as linhas posicionais para o nome real do campo" do
      result = service.notas_fiscais(codparc: 123)
      expect(result).to be_an(Array)
      expect(result.first).to eq(
        "NUNOTA" => "1001", "NUMNOTA" => "42", "DTNEG" => "15/05/2025",
        "VLRNOTA" => "12500.00", "CODPARC" => "6", "NOMEPARC" => "BEL DISTRIBUIDOR DE LUBRIFICANTES LTDA"
      )
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
