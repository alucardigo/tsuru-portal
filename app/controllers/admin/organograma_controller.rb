module Admin
  # Organograma: árvore da empresa por área — gestores no topo de cada área,
  # equipe direta (supervisor_id) aninhada, demais membros da área agrupados.
  class OrganogramaController < BaseController
    def index
      ativos = User.ativos
      @areas = Area.order(:name)

      @por_area = @areas.map do |area|
        membros = ativos.where(area: area.name).order(:name).to_a
        sups    = membros.select { |u| u.gestor? || u.admin? }
        sub_ids = sups.map(&:id)
        equipe_por_sup = sub_ids.any? ? ativos.where(supervisor_id: sub_ids).order(:name).group_by(&:supervisor_id) : {}
        alocados = sups + equipe_por_sup.values.flatten
        outros   = (membros - alocados)
        {
          area: area,
          supervisores: sups,
          equipe_por_sup: equipe_por_sup,
          outros: outros,
          total: (membros | equipe_por_sup.values.flatten).size,
          demandas: Demand.where(area_impactada: area.name).count
        }
      end

      @diretoria = ativos.where(role: :board).order(:name)
      @analistas = ativos.where(role: :analista_pdi).order(:name)
      @fi        = ativos.where(role: :fi).order(:name)
      @sem_area  = ativos.where(area: [ nil, "" ])
                         .where(role: %i[colaborador gestor admin])
                         .order(:name)
    end
  end
end
