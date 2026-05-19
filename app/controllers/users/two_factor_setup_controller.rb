class Users::TwoFactorSetupController < ApplicationController
  before_action :authenticate_user!

  def new
    secret = User.generate_otp_secret
    session[:pending_otp_secret] = secret
    @qr_svg = build_qr_svg(secret)
    @secret  = secret
  end

  def create
    secret = session[:pending_otp_secret]
    unless secret && ROTP::TOTP.new(secret).verify(params[:otp_attempt], drift_behind: 15)
      flash.now[:alert] = t("two_factor_setup.invalid_code")
      @qr_svg = build_qr_svg(secret)
      @secret = secret
      return render :new, status: :unprocessable_content
    end

    current_user.update!(otp_secret: secret, otp_required_for_login: true)
    session.delete(:pending_otp_secret)
    redirect_to backup_users_two_factor_setup_path,
                notice: t("two_factor_setup.enabled")
  end

  def backup
    @backup_codes = t("two_factor_setup.backup_placeholder")
  end

  def destroy
    current_user.update!(otp_required_for_login: false, otp_secret: nil)
    redirect_to edit_user_registration_path, notice: t("two_factor_setup.disabled")
  end

  private

  def build_qr_svg(secret)
    uri = current_user.otp_provisioning_uri(current_user.email,
                                             issuer: "Tsuru PD&I")
    RQRCode::QRCode.new(uri).as_svg(
      offset: 0, color: "000", shape_rendering: "crispEdges",
      module_size: 4, standalone: true
    )
  end
end
