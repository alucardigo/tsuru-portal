# frozen_string_literal: true

# Hook realtime Tsuru -> FI (LeidoBem). Marca no FiGroupProject espelho que há
# conteúdo N2 novo a empurrar, sempre que a Demand vinculada muda um dos campos
# textuais sincronizados (FiGroup::FieldMap::FIELD_PAIRS).
#
# Estratégia: NÃO faz HTTP aqui. Só levanta a flag push_pending; o CRON server-side
# (AutoSync via bin/rails runner) é quem de fato empurra pra API. Motivos:
#  - Em prod NÃO há job runner (SolidQueue abandonado), então nada de perform_later.
#  - Realtime barato: um único update_column, sem rede no caminho do save.
#  - Resiliente a token expirado: a pendência fica marcada e o cron empurra quando
#    houver credencial válida — nunca quebra o save da Demand por causa da FI.
module FiGroupSyncable
  extend ActiveSupport::Concern

  included do
    after_update_commit :flag_figroup_push_if_changed
  end

  private

  # Marca push_pending no espelho FI se algum campo sincronizado mudou neste save.
  def flag_figroup_push_if_changed
    fp = FiGroupProject.find_by(demand_id: id)
    return if fp.nil?

    # Atributos da Demand que sincronizam (values do FIELD_PAIRS), como string.
    mapped = FiGroup::FieldMap::FIELD_PAIRS.values.map(&:to_s)

    # Colunas reais mudadas que estão no mapa (ex.: title, solucao_proposta).
    changed_cols = (saved_changes.keys & mapped).any?

    # A maioria dos campos N2 (motivacao, barreira_tecnica, etc.) são
    # store_accessor sobre a coluna jsonb n2_assessment; saved_changes marca a
    # coluna inteira, então inspecionamos quais sub-chaves de fato mudaram.
    changed_n2 = false
    if saved_changes.key?("n2_assessment")
      before, after = saved_changes["n2_assessment"]
      before = (before || {})
      after  = (after  || {})
      changed_keys = (before.keys | after.keys).select { |k| before[k] != after[k] }
      changed_n2 = (changed_keys.map(&:to_s) & mapped).any?
    end

    return unless changed_cols || changed_n2

    fp.update_column(:push_pending, true)
  end
end
