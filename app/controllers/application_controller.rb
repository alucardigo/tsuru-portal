class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_user

  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  private

  def set_current_user
    Current.user = current_user
  end

  def pundit_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, status: :forbidden, alert: t("errors.not_authorized") }
      format.json { render json: { error: "Não autorizado" }, status: :forbidden }
    end
  end
end
