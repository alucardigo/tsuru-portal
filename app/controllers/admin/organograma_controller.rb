module Admin
  # Organograma: árvore genealógica real por supervisor_id.
  # Diretoria (role=board) no topo; qualquer gestor/admin sem supervisor_id definido
  # reporta diretamente à Diretoria; a partir daí a árvore segue supervisor_id recursivamente.
  class OrganogramaController < BaseController
    LEADERSHIP_ROLES = %w[gestor admin].freeze

    def index
      ativos = User.ativos

      @diretoria = ativos.where(role: :board).order(:name)
      @fi        = ativos.where(role: :fi).order(:name)
      @analistas = ativos.where(role: :analista_pdi).order(:name)

      # Topo da hierarquia (abaixo da diretoria): lideranças sem supervisor_id definido
      @nivel1 = ativos.where(role: LEADERSHIP_ROLES, supervisor_id: nil).order(:name)

      # Mapa supervisor_id -> filhos diretos, pra renderizar a árvore recursivamente
      @filhos_por_supervisor = ativos.where.not(supervisor_id: nil).order(:name).group_by(&:supervisor_id)

      # Colaboradores sem superior definido — não aparecem na árvore, ficam num bloco à parte
      ids_na_arvore = ([ @nivel1 ] + @filhos_por_supervisor.values).flatten.map(&:id).to_set
      @sem_hierarquia = ativos.where(role: %i[colaborador gestor admin])
                              .where.not(id: ids_na_arvore.to_a)
                              .order(:area, :name)
    end
  end
end
