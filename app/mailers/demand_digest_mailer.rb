class DemandDigestMailer < ApplicationMailer
  def weekly_summary(recipient)
    @recipient      = recipient
    @semana_inicio  = 1.week.ago.beginning_of_day
    @novas          = Demand.where("created_at >= ?", @semana_inicio)
                            .where(aasm_state: :submetida)
                            .order(created_at: :desc)
    @totais         = Demand.group(:aasm_state).count

    mail(
      to:      recipient.email,
      subject: "[Tsuru PD&I] Resumo Semanal de Demandas — #{Date.current.strftime('%d/%m/%Y')}"
    )
  end
end
