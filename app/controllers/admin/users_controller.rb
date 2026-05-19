module Admin
  class UsersController < BaseController
    def index
      @users = User.order(:name, :email)
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        redirect_to admin_users_path, notice: t("admin.users.updated")
      else
        redirect_to admin_users_path, alert: t("admin.users.update_failed")
      end
    end

    private

    def user_params
      # brakeman:ignore:MassAssignment - admin-only endpoint, role change is intentional
      params.require(:user).permit(:role)
    end
  end
end
