module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[update toggle_active vincular_superior]

    def index
      scope = User.all
      scope = scope.where(role: params[:role]) if params[:role].present?
      if params[:status] == "ativos"
        scope = scope.ativos
      elsif params[:status] == "inativos"
        scope = scope.inativos
      end
      if params[:q].present?
        like = "%#{User.sanitize_sql_like(params[:q])}%"
        scope = scope.where("name ILIKE :q OR email ILIKE :q", q: like)
      end
      @users = scope.order(:name, :email)
      @supervisores = supervisores_disponiveis
    end

    def new
      @user = User.new
      @supervisores = supervisores_disponiveis
    end

    def create
      @user = User.new(create_params)
      @user.password = params.dig(:user, :password).presence || SecureRandom.base58(16)
      @user.confirmed_at = Time.current if @user.respond_to?(:confirmed_at)
      if @user.save
        redirect_to admin_users_path, notice: "Usuário #{@user.display_name} incluído."
      else
        @supervisores = supervisores_disponiveis
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: t("admin.users.updated")
      else
        redirect_to admin_users_path, alert: t("admin.users.update_failed")
      end
    end

    # Inativar / reativar
    def toggle_active
      @user.update!(active: !@user.active)
      redirect_to admin_users_path,
                  notice: @user.active? ? "Usuário reativado." : "Usuário inativado."
    end

    # Vincular superior (supervisor) ao usuário
    def vincular_superior
      sup_id = params.dig(:user, :supervisor_id).presence
      @user.update!(supervisor_id: sup_id)
      redirect_to admin_users_path,
                  notice: sup_id ? "Superior vinculado a #{@user.display_name}." : "Vínculo de superior removido."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def supervisores_disponiveis
      User.where(role: %i[gestor admin]).ativos.order(:name)
    end

    def create_params
      # brakeman:ignore:MassAssignment - admin-only endpoint
      params.require(:user).permit(:name, :email, :role, :area, :supervisor_id)
    end

    def user_params
      # brakeman:ignore:MassAssignment - admin-only endpoint, role change is intentional
      params.require(:user).permit(:role, :area, :supervisor_id, :active, :name)
    end
  end
end
