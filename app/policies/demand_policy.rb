class DemandPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    owner? || gestor_or_above?
  end

  def create?
    true
  end

  def update?
    record.rascunho? && owner?
  end

  def submeter?
    record.rascunho? && owner?
  end

  def retomar?
    record.awaiting_requester? && owner?
  end

  # Etapa 2 — Supervisor aprova a sugestão
  def aprovar_supervisor?
    user.gestor? || user.admin?
  end

  # Etapa 4 — Diretoria encaminha à FI
  def aprovar_diretoria?
    user.board? || user.admin?
  end

  # Etapa 5 — FI Group dá parecer
  def fi_decisao?
    user.fi? || user.admin?
  end

  # Etapa 6 — vira Projeto de Fato
  def tornar_projeto?
    user.admin? || user.board? || user.analista_pdi?
  end

  def iniciar_triagem?
    user.analista_pdi? || user.admin? || user.gestor?
  end

  def aprovar_n1?
    gestor_or_above?
  end

  def reprovar_n1?
    gestor_or_above?
  end

  def triagem?
    gestor_or_above?
  end

  def update_triagem?
    gestor_or_above?
  end

  def iniciar_n2?
    user.analista_pdi? || user.admin?
  end

  def n2?
    user.analista_pdi? || user.admin?
  end

  def decidir_elegibilidade?
    user.analista_pdi? || user.admin?
  end

  def versions?
    owner? || gestor_or_above?
  end

  def destroy?
    (record.rascunho? && owner?) || user.admin?
  end

  def arquivar?      = user.admin? || owner?
  def hard_destroy?  = user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.colaborador?
        scope.where(user: user)
      elsif user.fi?
        # FI vê o que está na sua fila + o que já avaliou
        scope.where(aasm_state: %w[em_avaliacao_fi elegivel nao_elegivel projeto])
      else
        scope.all
      end
    end
  end

  private

  def owner?
    record.user == user
  end

  def gestor_or_above?
    user.gestor? || user.analista_pdi? || user.admin? || user.board?
  end
end
