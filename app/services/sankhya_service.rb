class SankhyaService
  GATEWAY = "https://api.sankhya.com.br/gateway/v1"

  def initialize(client: SankhyaClient.new)
    @client = client
    @http = Faraday.new(GATEWAY) do |f|
      f.response :raise_error
      f.adapter Faraday.default_adapter
    end
  end

  def notas_fiscais(codparc:)
    response = gateway_post(notas_fiscais_payload(codparc))
    rows = JSON.parse(response.body).dig("responseBody", "entities", "entity") || []
    rows = [ rows ] unless rows.is_a?(Array)
    rows
  end

  def registrar_adiantamento(codprojeto:, valor:, descricao:)
    response = gateway_post(adiantamento_payload(codprojeto, valor, descricao))
    JSON.parse(response.body)
  end

  private

  def gateway_post(payload)
    token = @client.token
    @http.post("mge/service.sbr") do |req|
      req.headers["Authorization"] = "Bearer #{token}"
      req.headers["Content-Type"]  = "application/json"
      req.body = payload.to_json
    end
  end

  def notas_fiscais_payload(codparc)
    {
      serviceName: "CRUDServiceProvider.loadRecords",
      requestBody: {
        dataSet: {
          rootEntity: "CabecalhoNota",
          includePresentationFields: "S",
          offsetPage: "0",
          criteria: {
            expression: { "$": "this.CODPARC = #{codparc.to_i} AND this.TIPMOV = 'C'" }
          },
          entity: {
            fieldset: { list: "NUNOTA,NUMNOTA,DTNEG,VLRNOTA,CODPARC,NOMEPARC" }
          }
        }
      }
    }
  end

  def adiantamento_payload(codprojeto, valor, descricao)
    {
      serviceName: "CRUDServiceProvider.save",
      requestBody: {
        dataSet: {
          rootEntity: "AdiantamentoRD",
          entity: {
            record: {
              CODPROJETO: codprojeto,
              VLRADIANT: valor,
              DESCRICAO: descricao,
              DTADIANT: Time.current.strftime("%d/%m/%Y")
            }
          }
        }
      }
    }
  end
end
