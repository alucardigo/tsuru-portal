module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      unless current_user&.admin?
        respond_to do |format|
          format.html { redirect_to root_path, status: :forbidden, alert: t("errors.not_authorized") }
          format.json { render json: { error: "Não autorizado" }, status: :forbidden }
          format.any  { head :forbidden }
        end
      end
    end
  end
end
