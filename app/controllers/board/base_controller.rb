module Board
  class BaseController < ApplicationController
    before_action :require_board_access!

    private

    def require_board_access!
      return if current_user&.board? || current_user&.admin?

      redirect_to root_path, alert: "Acesso restrito à diretoria."
    end
  end
end
