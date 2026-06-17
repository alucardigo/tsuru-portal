module Admin
  # Organograma: hierarquia por área (superior -> equipe) estilo árvore.
  class OrganogramaController < BaseController
    def index
      gestores = User.where(role: :gestor).ativos
      @por_area = Demand::AREAS.map do |area|
        sups = gestores.select { |g| g.area == area }
        ids  = sups.map(&:id)
        equipe = ids.any? ? User.where(supervisor_id: ids).ativos.order(:name) : User.none
        { area: area, supervisores: sups, equipe: equipe, demandas: Demand.where(area_impactada: area).count }
      end

      @sem_area = gestores.select { |g| g.area.blank? }
      @diretoria = User.where(role: :board).ativos.order(:name)
      @admins    = User.where(role: :admin).ativos.order(:name)
      @analistas = User.where(role: :analista_pdi).ativos.order(:name)
      @fi        = User.where(role: :fi).ativos.order(:name)
    end
  end
end
