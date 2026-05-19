class Users::SessionsController < Devise::SessionsController
  prepend_before_action :authenticate_with_two_factor, only: :create

  private

  def authenticate_with_two_factor
    user = find_user_for_two_factor
    return unless user&.otp_required_for_login

    if user_params[:otp_attempt].present?
      authenticate_user_with_two_factor(user)
    else
      prompt_for_two_factor(user)
    end
  end

  def find_user_for_two_factor
    User.find_by(email: user_params[:email])&.tap do |u|
      u.valid_password?(user_params[:password]) ? u : nil
    end
  end

  def authenticate_user_with_two_factor(user)
    if user.validate_and_consume_otp!(user_params[:otp_attempt])
      sign_in(resource_name, user)
      redirect_to after_sign_in_path_for(user)
    else
      flash.now[:alert] = t("devise.two_factor_authentication.code_invalid")
      render :two_factor
    end
  end

  def prompt_for_two_factor(user)
    @user = user
    render :two_factor
  end

  def user_params
    params.require(:user).permit(:email, :password, :otp_attempt, :remember_me)
  end
end
