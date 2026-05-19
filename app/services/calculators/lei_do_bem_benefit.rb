# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

module Calculators
  # Calcula o beneficio fiscal da Lei do Bem (Lei 11.196/2005, Decreto 5.798/2006).
  #
  # Regras aplicadas:
  # - Exclusao base IRPJ/CSLL: 60% sobre dispendios PD&I (Art. 19, caput).
  # - Adicional de 20% para pesquisadores contratados no ano-base (Art. 19, § 1, II).
  # - Adicional de 20% para projetos com patente concedida (Art. 19, § 3).
  # - Aliquota efetiva combinada IRPJ (25%) + adicional (10%) + CSLL (9%) = 34%.
  #
  # Para simplificacao da estimativa, aplicamos a aliquota efetiva sobre o total
  # da exclusao. O calculo final por trimestre/ano deve respeitar regime e teto
  # do lucro liquido (art. 17, § 5), mas a estimativa aqui suporta planejamento.
  class LeiDoBemBenefit
    Result = Struct.new(:success?, :payload, :reason, :errors, keyword_init: true)

    PERCENTUAL_BASE             = BigDecimal("0.60").freeze
    PERCENTUAL_ADICIONAL_PESQ   = BigDecimal("0.20").freeze
    PERCENTUAL_ADICIONAL_PATENTE = BigDecimal("0.20").freeze
    ALIQUOTA_EFETIVA            = BigDecimal("0.34").freeze
    ESCALA_MONETARIA            = 2

    def self.call(record:)
      new(record).call
    end

    def initialize(record)
      @record = record
    end

    def call
      return failure(:invalid_record, [ "record nao pode ser nil" ]) if @record.nil?

      dispendios = normalize_dispendios(@record.total_dispendios)
      return failure(:invalid_dispendios, [ "total_dispendios deve ser >= 0" ]) if dispendios.negative?

      exclusao_base           = round_money(dispendios * PERCENTUAL_BASE)
      adicional_pesquisadores = adicional_pesq(dispendios)
      adicional_patente       = adicional_patente_valor(dispendios)
      exclusao_total          = round_money(exclusao_base + adicional_pesquisadores + adicional_patente)
      economia_tributaria     = round_money(exclusao_total * ALIQUOTA_EFETIVA)
      percentual_aplicado     = percentual_aplicado_total

      success(
        dispendios: dispendios,
        percentual_aplicado: percentual_aplicado,
        exclusao_base: exclusao_base,
        adicional_pesquisadores: adicional_pesquisadores,
        adicional_patente: adicional_patente,
        exclusao_total: exclusao_total,
        economia_tributaria: economia_tributaria,
        regime_tributacao: @record.regime_tributacao,
        aliquota_efetiva: ALIQUOTA_EFETIVA
      )
    end

    private

    def normalize_dispendios(valor)
      return BigDecimal("0") if valor.nil?
      return valor if valor.is_a?(BigDecimal)

      BigDecimal(valor.to_s)
    end

    def adicional_pesq(dispendios)
      return BigDecimal("0") unless @record.base_zero_pesquisadores

      round_money(dispendios * PERCENTUAL_ADICIONAL_PESQ)
    end

    def adicional_patente_valor(dispendios)
      return BigDecimal("0") unless @record.tem_patente

      round_money(dispendios * PERCENTUAL_ADICIONAL_PATENTE)
    end

    def percentual_aplicado_total
      total = PERCENTUAL_BASE
      total += PERCENTUAL_ADICIONAL_PESQ if @record.base_zero_pesquisadores
      total += PERCENTUAL_ADICIONAL_PATENTE if @record.tem_patente
      total
    end

    def round_money(value)
      value.round(ESCALA_MONETARIA, BigDecimal::ROUND_HALF_UP)
    end

    def success(**payload)
      Result.new(success?: true, payload: payload, reason: nil, errors: [])
    end

    def failure(reason, errors)
      Result.new(success?: false, payload: nil, reason: reason, errors: errors)
    end
  end
end
