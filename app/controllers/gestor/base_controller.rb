module Gestor
  class BaseController < ApplicationController
    before_action :require_gestor_access!

    private

    def require_gestor_access!
      return if current_user&.gestor_or_above?

      redirect_to root_path, alert: "Acesso restrito a superiores/gestores."
    end
  end
end
