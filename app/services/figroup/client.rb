# frozen_string_literal: true

# Integração server-side com a API interna do LeidoBem (FI Group).
#
# Toda comunicação é feita direto do Rails (via Faraday), sem browser e sem
# cookie: a API interna do LeidoBem aceita apenas o header
# "Authorization: Bearer <JWT>". O token (~1h de vida) é capturado uma vez por
# sessão no navegador e armazenado em FiGroupCredential; aqui apenas o
# reutilizamos como Bearer nas chamadas server-side.
#
# Contrato completo em docs/FIGROUP_API_CONTRATO.md.
module FiGroup
  # FiGroup::AuthError vive em app/services/figroup/auth_error.rb (autoloadable).

  class Client
    # credential: FiGroupCredential ativo. Por padrão pega o mais recente.
    # Sem credencial ou credencial expirada => AuthError.
    def initialize(credential = FiGroupCredential.current)
      raise AuthError, "sem credencial ativa" if credential.nil? || !credential.active?

      @credential = credential
    end

    # GET /Company/{company_id} -> Hash com dados do tenant (inclui services[]).
    def company
      get("/Company/#{@credential.company_id}")
    end

    # GET /Projects/GetProjectsByServiceId/{sid} -> Array de projetos
    # (extrai o campo 'projects' do corpo).
    def projects(service_id)
      body = get("/Projects/GetProjectsByServiceId/#{service_id}")
      extract_projects(body)
    end

    # GET /Projects/{id} -> Hash com o objeto completo do projeto
    # (mesma forma usada no PUT).
    def project(project_id)
      get("/Projects/#{project_id}")
    end

    # GET /Projects/GetEligibilityCount/{sid} -> Hash
    # (ex.: {"elegivel"=>13,"naoElegivel"=>2,"talvez"=>0,"pendente"=>0}).
    def eligibility_count(service_id)
      get("/Projects/GetEligibilityCount/#{service_id}")
    end

    # GET /Service/GetServiceCategoryExpenditures/{sid} -> Hash
    # (dispêndios por categoria: rhValues/stValues/mcValues/bpValues).
    def category_expenditures(service_id)
      get("/Service/GetServiceCategoryExpenditures/#{service_id}")
    end

    # PUT /Projects/{id} (JSON) -> Hash (corpo da resposta).
    # Envia o objeto inteiro (padrão da API: GET -> altera -> PUT de volta).
    def update_project(project_id, payload)
      put("/Projects/#{project_id}", payload)
    end

    private

    # Extrai o array de projetos do corpo, tolerando chave string ou symbol.
    def extract_projects(body)
      return [] if body.nil?
      return body if body.is_a?(Array)
      return [] unless body.is_a?(Hash)

      body["projects"] || body[:projects] || []
    end

    def get(path)
      handle(conn.get(url_for(path)))
    rescue Faraday::UnauthorizedError => e
      raise AuthError, "não autorizado (401): #{e.message}"
    end

    def put(path, body)
      handle(conn.put(url_for(path), body))
    rescue Faraday::UnauthorizedError => e
      raise AuthError, "não autorizado (401): #{e.message}"
    end

    # Monta a URL absoluta. base_url = ".../api/services"; um path com barra
    # inicial faria o Faraday DESCARTAR o "/api/services" (resolução RFC 3986 de
    # path absoluto) e cair no 404 do SPA — por isso montamos a URL completa aqui.
    def url_for(path)
      "#{@credential.base_url.chomp('/')}/#{path.to_s.sub(%r{\A/+}, '')}"
    end

    # Trata a resposta: 401 vira AuthError; demais erros HTTP propagam.
    def handle(response)
      raise AuthError, "token expirado ou inválido (401)" if response.status == 401

      response.body
    end

    # Conexão Faraday memoizada. base_url da credencial, JSON in/out,
    # Bearer capturado e retry (faraday-retry) para instabilidades transitórias.
    def conn
      @conn ||= Faraday.new(url: @credential.base_url) do |f|
        f.request :json
        f.request :retry, max: 2, interval: 0.3, backoff_factor: 2,
                          retry_statuses: [ 429, 500, 502, 503, 504 ],
                          methods: %i[get put]
        f.response :json, content_type: /json/
        f.headers["Authorization"] = "Bearer #{@credential.token}"
        f.headers["Accept"] = "application/json"
        f.adapter Faraday.default_adapter
      end
    end
  end
end
