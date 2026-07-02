# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Mesma lógica de Admin::OrganogramaController (árvore genealógica por supervisor_id),
      # servida em JSON para agentes de código lerem a hierarquia.
      class OrganogramaController < BaseController
        LEADERSHIP_ROLES = %w[gestor admin].freeze

        def index
          ativos = User.ativos
          filhos_por_supervisor = ativos.where.not(supervisor_id: nil).order(:name).group_by(&:supervisor_id)
          nivel1 = ativos.where(role: LEADERSHIP_ROLES, supervisor_id: nil).order(:name)

          ids_na_arvore = ([ nivel1 ] + filhos_por_supervisor.values).flatten.map(&:id).to_set
          sem_hierarquia = ativos.where(role: %i[colaborador gestor admin])
                                  .where.not(id: ids_na_arvore.to_a)
                                  .order(:area, :name)

          render json: {
            diretoria: ativos.where(role: :board).order(:name).map { |u| brief(u) },
            hierarquia: nivel1.map { |u| node(u, filhos_por_supervisor) },
            fi: ativos.where(role: :fi).order(:name).map { |u| brief(u) },
            analistas: ativos.where(role: :analista_pdi).order(:name).map { |u| brief(u) },
            sem_hierarquia: sem_hierarquia.map { |u| brief(u) }
          }
        end

        private

        def node(user, filhos_por_supervisor)
          filhos = filhos_por_supervisor[user.id] || []
          brief(user).merge(subordinados: filhos.map { |f| node(f, filhos_por_supervisor) })
        end

        def brief(user)
          { id: user.id, name: user.name, role: user.role, area: user.area, supervisor_id: user.supervisor_id }
        end
      end
    end
  end
end
