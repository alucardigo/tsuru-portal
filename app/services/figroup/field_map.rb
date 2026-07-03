# frozen_string_literal: true

# Mapeamento de campos entre o objeto de projeto da API interna do LeidoBem
# (FI Group) e o model Demand do Tsuru.
#
# Parte da integração server-side com a API interna do LeidoBem (token Bearer
# capturado): esta camada é pura (sem HTTP), converte um Hash de projeto FI
# (retorno de GET /Projects/{id}) em atributos da Demand e vice-versa, e calcula
# o diff antes de um PUT.
#
# Contrato completo em docs/FIGROUP_API_CONTRATO.md.
module FiGroup
  module FieldMap
    module_function

    # Enums da API (GET /enum/*). Índice inteiro => rótulo humano.
    ELIGIBILITY = { 1 => "Elegível", 2 => "Não Elegível", 3 => "Talvez", 4 => "Pendente" }.freeze

    NATURE = {
      1 => "Produto",
      2 => "Processo",
      3 => "Serviço por Produto Novo",
      4 => "Produto Melhorado",
      5 => "Processo Novo",
      6 => "Processo Melhorado",
      7 => "Serviço Novo",
      8 => "Serviço Melhorado"
    }.freeze

    ESCOPE = { 1 => "Mercado", 2 => "País", 3 => "Empresa" }.freeze

    # Pares campo_FI (string, chave no objeto do LeidoBem) => atributo Demand (symbol).
    # Somente os campos textuais de conteúdo N2 que sincronizam nos dois sentidos.
    FIELD_PAIRS = {
      "name"                  => :title,
      "objective"             => :solucao_proposta,
      "why"                   => :motivacao,
      "beforeAfterDifference" => :benchmark_anterior,
      "developmentPlanning"   => :metodologia,
      "techChallenge"         => :barreira_tecnica,
      "advances"              => :resultado_obtido,
      "techUsed"              => :stack_tecnologico
    }.freeze

    # fi = Hash do /Projects/{id}.
    # Retorna Hash {atributo_demand => valor} só com os campos presentes e
    # não-vazios no objeto FI (pula em branco/nil), para atualizar a Demand.
    def demand_attrs_from_fi(fi)
      fi = stringify(fi)
      attrs = {}
      FIELD_PAIRS.each do |fi_field, demand_attr|
        value = fi[fi_field]
        attrs[demand_attr] = value if present?(value)
      end
      attrs
    end

    # Retorna uma cópia do objeto FI (Hash) com os valores dos campos do Tsuru
    # sobrescrevendo, quando o valor no Tsuru estiver presente/não-vazio.
    # Preserva todo o resto do objeto FI intacto (é um PUT do objeto inteiro).
    def apply_tsuru_onto_fi(fi_object, demand)
      result = stringify(fi_object).dup
      return result if demand.nil?

      FIELD_PAIRS.each do |fi_field, demand_attr|
        tsuru_value = demand.public_send(demand_attr) if demand.respond_to?(demand_attr)
        result[fi_field] = tsuru_value if present?(tsuru_value)
      end
      result
    end

    # Retorna Hash {campo_fi => {de:, para:}} só onde apply_tsuru_onto_fi
    # realmente mudaria o valor (comparação de valor atual x valor do Tsuru).
    def diff(fi_object, demand)
      original = stringify(fi_object)
      updated = apply_tsuru_onto_fi(fi_object, demand)
      changes = {}
      FIELD_PAIRS.each_key do |fi_field|
        de = original[fi_field]
        para = updated[fi_field]
        changes[fi_field] = { de: de, para: para } unless equivalent?(de, para)
      end
      changes
    end

    # Compara valores tratando travessões unicode (a FI normaliza em-dash "—"
    # para en-dash "–" ao salvar) e espaços como equivalentes — evita re-empurrar
    # um campo eternamente só por causa dessa normalização do servidor.
    def equivalent?(a, b)
      normalize_compare(a) == normalize_compare(b)
    end

    def normalize_compare(value)
      value.to_s.gsub(/[‐-―−]/, "-").gsub(/\s+/, " ").strip
    end

    # --- helpers privados (module_function torna-os também callables internos) ---

    # Considera "presente" apenas valores não-nil que, sendo string, não são
    # vazios/só-espaço. Números/booleans presentes contam como presentes.
    def present?(value)
      return false if value.nil?
      return !value.strip.empty? if value.is_a?(String)

      true
    end

    # Normaliza chaves para string sem mutar o Hash original.
    # Aceita Hash com chaves string ou symbol; devolve sempre chaves string.
    def stringify(hash)
      return {} if hash.nil?
      return hash if hash.is_a?(Hash) && hash.keys.all?(String)

      hash.to_h.transform_keys(&:to_s)
    end
  end
end
