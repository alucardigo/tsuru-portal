# frozen_string_literal: true

module FiGroup
  # Puxa projetos do LeidoBem (FI Group) para o Tsuru.
  #
  # Fluxo:
  #   - resolve o service_id do ano a partir da credencial;
  #   - lista os projetos do serviço (client.projects(sid));
  #   - para cada projeto faz upsert de FiGroupProject por fi_project_id;
  #   - tenta vincular a uma Demand comparando normalize_code(codeProject)
  #     com normalize_code(demand.codigo);
  #   - ao vincular, atualiza position_fi/eligibility no FiGroupProject.
  #
  # NÃO altera a Demand automaticamente (apenas vincula). Erros por projeto
  # são acumulados em :errors sem abortar o lote inteiro.
  class PullSync
    def initialize(credential = FiGroupCredential.current, year: Time.current.year)
      @credential = credential
      @year = year
      @client = FiGroup::Client.new(@credential)
    end

    # @return [Hash] { projects_synced:, linked:, unlinked:, errors: [] }
    def call
      result = { projects_synced: 0, linked: 0, unlinked: 0, errors: [] }

      service_id = @credential&.service_id_for(@year)
      if service_id.blank?
        result[:errors] << "sem service_id para o ano #{@year}"
        return result
      end

      projects = @client.projects(service_id)

      Array(projects).each do |proj|
        begin
          fp = upsert_project(proj, service_id)

          if fp.linked?
            result[:linked] += 1
          else
            result[:unlinked] += 1
          end

          result[:projects_synced] += 1
        rescue FiGroup::AuthError
          # Token expirado/invalido invalida o lote inteiro: propaga para o caller.
          raise
        rescue StandardError => e
          code = proj.is_a?(Hash) ? (proj["codeProject"] || proj["id"]) : proj
          result[:errors] << "#{code}: #{e.message}"
        end
      end

      result
    end

    private

    # Cria ou atualiza o FiGroupProject correspondente e tenta vincular a Demand.
    def upsert_project(proj, service_id)
      proj = proj.to_h
      fi_id = proj["id"].to_s

      fp = FiGroupProject.find_or_initialize_by(fi_project_id: fi_id)

      fp.service_id     = service_id
      fp.fiscal_year    = @year
      fp.code_project   = proj["codeProject"]
      fp.name           = proj["name"]
      fp.eligibility    = eligibility_value(proj["eligibility"])
      fp.raw            = summary(proj)
      fp.last_pulled_at = Time.current

      # Tenta vincular a uma Demand pela normalizacao do codigo.
      demand = find_demand_for(proj["codeProject"])
      if demand
        fp.demand = demand
        fp.position_fi = proj["positionFI"] if proj.key?("positionFI")
        # eligibility ja definido acima a partir do proprio projeto.
      end

      fp.save!
      fp
    end

    # A listagem (GetProjectsByServiceId) traz eligibility como rotulo string
    # ("Elegível"); o detalhe traz inteiro (1-4). Aceita ambos.
    def eligibility_value(raw)
      return raw if raw.is_a?(Integer)

      case raw.to_s.strip.downcase
      when "elegível", "elegivel" then 1
      when "não elegível", "nao elegivel" then 2
      when "talvez" then 3
      when "pendente" then 4
      end
    end

    # Vincula por normalize_code(codeProject) == normalize_code(demand.codigo).
    def find_demand_for(code_project)
      normalized = FiGroupProject.normalize_code(code_project)
      return nil if normalized.blank?

      Demand.where.not(codigo: [ nil, "" ]).find do |demand|
        FiGroupProject.normalize_code(demand.codigo) == normalized
      end
    end

    # Resumo compacto do projeto guardado em raw (jsonb).
    def summary(proj)
      {
        "id"          => proj["id"],
        "name"        => proj["name"],
        "codeProject" => proj["codeProject"],
        "eligibility" => proj["eligibility"],
        "department"  => proj["department"],
        "nature"      => proj["nature"],
        "area"        => proj["area"],
        "typology"    => proj["typology"],
        "startDate"   => proj["startDate"],
        "endDate"     => proj["endDate"]
      }.compact
    end
  end
end
