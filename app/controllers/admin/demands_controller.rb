module Admin
  class DemandsController < BaseController
    def formpd
    demand = Demand.find(params[:id])
    render json: demand.to_formpd
  end

  def index
      @demands = Demand.includes(:user).order(created_at: :desc)
      @demands = @demands.where(aasm_state: params[:estado]) if params[:estado].present?

      respond_to do |format|
        format.html { }
        format.csv  { render_csv }
      end
    end

    private

    def render_csv
      csv_data = CSV.generate(headers: true) do |csv|
        csv << %w[ID Título Solicitante Estado Criada Parecer]
        @demands.each do |d|
          csv << [ d.id, d.title, d.user.display_name, d.aasm_state,
                  d.created_at.strftime("%d/%m/%Y"), d.parecer_tecnico ]
        end
      end
      send_data csv_data,
                filename: "demandas-#{Date.current.iso8601}.csv",
                type: "text/csv; charset=utf-8"
    end
  end
end
