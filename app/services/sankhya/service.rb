module Sankhya
  class Service
    GATEWAY = "https://api.sankhya.com.br/gateway/v1"

    def initialize(client: Sankhya::Client.new)
      @client = client
      @http = Faraday.new(GATEWAY) do |f|
        f.response :raise_error
        f.adapter Faraday.default_adapter
      end
    end

    NOTAS_FISCAIS_CAMPOS = %w[NUNOTA NUMNOTA DTNEG VLRNOTA CODPARC NOMEPARC].freeze

    def notas_fiscais(codparc:)
      response = gateway_post(notas_fiscais_payload(codparc), operation: "notas_fiscais")
      rows = JSON.parse(response.body).dig("responseBody", "entities", "entity") || []
      rows = [ rows ] unless rows.is_a?(Array)
      rows.map { |row| remap_row(row, NOTAS_FISCAIS_CAMPOS) }
    end

    def registrar_adiantamento(codprojeto:, valor:, descricao:)
      response = gateway_post(
        adiantamento_payload(codprojeto, valor, descricao),
        operation: "registrar_adiantamento"
      )
      JSON.parse(response.body)
    end

    # Bloco I — consulta genérica a qualquer entidade Sankhya (CRUDServiceProvider.loadRecords).
    # Usado pelo SankhyaMapping configurável para sincronizar colaboradores/PJ/projetos/notas
    # sem precisar de um método dedicado por entidade.
    def consultar(entidade:, campos:, criterio: nil)
      campos = Array(campos)
      payload = {
        serviceName: "CRUDServiceProvider.loadRecords",
        requestBody: {
          dataSet: {
            rootEntity: entidade,
            includePresentationFields: "S",
            offsetPage: "0",
            entity: { fieldset: { list: campos.join(",") } }
          }
        }
      }
      payload[:requestBody][:dataSet][:criteria] = { expression: { "$": criterio } } if criterio.present?

      response = gateway_post(payload, operation: "consultar_#{entidade}")
      rows = JSON.parse(response.body).dig("responseBody", "entities", "entity") || []
      rows = [ rows ] unless rows.is_a?(Array)
      rows.map { |row| remap_row(row, campos) }
    end

    private

    # O gateway devolve cada linha com chaves posicionais f0,f1,f2... (na ordem
    # do fieldset enviado), cada valor embrulhado em {"$" => valor}. Remapeia
    # para {nome_do_campo => valor} — sem isso, row["CODPARC"] nunca existe.
    def remap_row(row, campos)
      campos.each_with_index.each_with_object({}) do |(campo, idx), acc|
        raw = row["f#{idx}"]
        acc[campo] = raw.is_a?(Hash) ? raw["$"] : raw
      end
    end

    def gateway_post(payload, operation:)
      correlation_id = SecureRandom.uuid
      token = @client.token

      Sankhya::AuditLog.call(
        operation: operation,
        correlation_id: correlation_id,
        request_payload: payload
      )

      # O service.sbr exige serviceName na query e outputType=json (senão volta XML).
      service_name = payload[:serviceName] || payload["serviceName"]
      response = @http.post("mge/service.sbr") do |req|
        req.params["serviceName"] = service_name
        req.params["outputType"]  = "json"
        req.headers["Authorization"]    = "Bearer #{token}"
        req.headers["Content-Type"]     = "application/json"
        req.headers["X-Correlation-Id"] = correlation_id
        req.body = payload.to_json
      end

      Sankhya::AuditLog.call(
        operation: operation,
        correlation_id: correlation_id,
        request_payload: payload,
        response_status: response.status,
        response_body: response.body
      )

      response
    rescue Faraday::Error => e
      Sankhya::AuditLog.call(
        operation: operation,
        correlation_id: correlation_id,
        request_payload: payload,
        error: e.message
      )
      raise
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
end
