class DemandMailer < ApplicationMailer
  def submetida(demand)
    @demand = demand
    gestores = User.where(role: %i[gestor analista_pdi admin])
    mail(
      to: gestores.pluck(:email),
      subject: t("demand_mailer.submetida.subject", title: demand.title)
    )
  end

  def n1_aprovada(demand)
    @demand = demand
    mail(to: demand.user.email, subject: t("demand_mailer.n1_aprovada.subject"))
  end

  def n1_reprovada(demand)
    @demand = demand
    mail(to: demand.user.email, subject: t("demand_mailer.n1_reprovada.subject"))
  end

  def elegivel(demand)
    @demand = demand
    mail(to: demand.user.email, subject: t("demand_mailer.elegivel.subject"))
  end
end
