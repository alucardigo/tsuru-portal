# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def create_for_demand
          demand = Demand.find(params[:demand_id])
          report = Ai::ReportGenerator.project_summary(demand: demand, requested_by: @current_api_user)
          render_report(report)
        end

        def create_portfolio
          report = Ai::ReportGenerator.portfolio_insight(requested_by: @current_api_user)
          render_report(report)
        end

        private

        def render_report(report)
          if report.ok?
            render json: { id: report.id, kind: report.kind, content: report.content }
          else
            render json: { id: report.id, error: report.error }, status: :unprocessable_content
          end
        end
      end
    end
  end
end
