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

  def iniciar_triagem?
    gestor_or_above?
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.colaborador?
        scope.where(user: user)
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
