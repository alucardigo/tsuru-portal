module Validators
  # Valida redacao de campos textuais Lei do Bem (barreira_tecnica,
  # resultado_obtido, metodologia, etc.) contra padroes que causam glosa CAT-MCTI:
  #
  #   - Termos vagos/subjetivos ("ficou mais rapido", "melhorou")
  #   - Barreira de PMO disfarcada de tecnica (prazo, orcamento, equipe)
  #   - Ausencia de quantitativos verificaveis (ms, %, R$, MB, fps, rps...)
  #
  # Inspirado em "Linus rant style review": rigor brutal, nada de fluff.
  #
  # Retorna Result struct (success?, payload, reason, errors) — padrao do projeto.
  class LinusRedaction
    Result = Struct.new(:success?, :payload, :reason, :errors, keyword_init: true)

    BANNED_PHRASES = [
      "ficou mais rapido", "ficou mais rapido",
      "melhorou", "ganho expressivo",
      "ficou melhor", "otimizacao do sistema", "otimizacao do sistema",
      "houve melhoria", "trouxe ganhos", "trouxe melhorias"
    ].freeze

    PMO_TERMS = [
      "prazo apertado", "equipe sem treinamento", "fornecedor atrasado",
      "orcamento limitado", "orcamento limitado", "falta de recursos humanos"
    ].freeze

    QUANTITATIVE_REGEX = %r{\d+[.,]?\d*\s*(ms|s|%|R\$|mb|gb|kb|fps|rps|req/s|tps)}i

    REASON = "Redacao com problemas que levam a glosa Lei do Bem".freeze

    def self.call(text:, require_quantitative: true)
      new(text, require_quantitative).call
    end

    def initialize(text, require_quantitative)
      @text = text.to_s
      @require_quantitative = require_quantitative
    end

    def call
      violations = []
      normalized = normalize(@text)

      banned_found = BANNED_PHRASES.select { |p| normalized.include?(normalize(p)) }.uniq
      pmo_found    = PMO_TERMS.select { |p| normalized.include?(normalize(p)) }.uniq

      violations << { type: :banned_phrase, terms: banned_found } if banned_found.any?
      violations << { type: :pmo_disguised_as_technical, terms: pmo_found } if pmo_found.any?

      if @require_quantitative && !@text.match?(QUANTITATIVE_REGEX)
        violations << {
          type: :missing_quantitative,
          message: "texto sem metricas verificaveis (ms/s/%/R$/MB/GB/fps/rps/req/s/tps)"
        }
      end

      if violations.empty?
        Result.new(success?: true, payload: { text: @text, length: @text.length })
      else
        Result.new(success?: false, errors: violations, reason: REASON)
      end
    end

    private

    # Lower-case + remove acentos para casar "orçamento" == "orcamento",
    # "rápido" == "rapido", "RÁPIDO" == "rapido", etc.
    def normalize(str)
      str.to_s.downcase.unicode_normalize(:nfd).gsub(/\p{Mn}/, "")
    end
  end
end
