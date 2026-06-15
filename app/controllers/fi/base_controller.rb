module Fi
  class BaseController < ApplicationController
    before_action :require_fi_access!

    private

    def require_fi_access!
      return if current_user&.fi? || current_user&.admin?

      redirect_to root_path, alert: "Acesso restrito à consultoria FI Group."
    end
  end
end
