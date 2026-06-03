# frozen_string_literal: true

# Acesso: admin/analista veem e mexem em qualquer task.
# Autor da demand cria/edita tasks dos próprios projetos.
# Gestor pode ver e mover tasks de demands da sua área.
class ProjectTaskPolicy < ApplicationPolicy
  def index?      = view_demand?
  def show?       = view_demand?
  def create?     = manage_demand?
  def update?     = manage_demand?
  def destroy?    = manage_demand?
  def move?       = manage_demand? || gestor_da_area?
  def kanban?     = view_demand?

  private

  def view_demand?
    return false unless user
    user.admin? || user.analista_pdi? || user.board? || user.gestor? ||
      record.demand.user_id == user.id
  end

  def manage_demand?
    return false unless user
    user.admin? || user.analista_pdi? ||
      record.demand.user_id == user.id
  end

  def gestor_da_area?
    return false unless user&.gestor?
    # gestor da área da demand pode mover (cobertura simplificada por enquanto)
    record.demand.area_impactada.present?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      if user.admin? || user.analista_pdi? || user.board?
        scope.all
      elsif user.gestor?
        scope.joins(:demand) # gestor vê tudo, podemos refinar por area
      else
        scope.joins(:demand).where(demands: { user_id: user.id })
      end
    end
  end
end
