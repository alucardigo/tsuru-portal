# frozen_string_literal: true

# Sprint authorization — reusa regra: admin/analista_pdi ou autor da demand.
class SprintPolicy < ApplicationPolicy
  def index?   = manage?
  def show?    = manage?
  def create?  = manage?
  def update?  = manage?
  def destroy? = manage?
  def assign_task?   = manage?
  def unassign_task? = manage?

  private

  def manage?
    return false unless user
    demand = record.is_a?(Demand) ? record : record&.demand
    return false unless demand
    user.admin? || user.analista_pdi? || demand.user_id == user.id
  end
end
