require "rails_helper"

RSpec.describe "2FA Setup", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /users/two_factor_setup/new" do
    it "retorna 200" do
      get new_users_two_factor_setup_path
      expect(response).to have_http_status(:ok)
    end

    it "contém QR code SVG" do
      get new_users_two_factor_setup_path
      expect(response.body).to include("<svg")
    end

    it "contém campo de verificação OTP" do
      get new_users_two_factor_setup_path
      expect(response.body).to include("otp_attempt")
    end
  end

  describe "POST /users/two_factor_setup" do
    context "when código OTP válido" do
      it "ativa 2FA e redireciona" do
        get new_users_two_factor_setup_path
        secret = session[:pending_otp_secret]
        valid_otp = ROTP::TOTP.new(secret).now
        post users_two_factor_setup_path, params: { otp_attempt: valid_otp }
        expect(response).to redirect_to(backup_users_two_factor_setup_path)
      end

      it "marca otp_required_for_login como true" do
        get new_users_two_factor_setup_path
        secret = session[:pending_otp_secret]
        valid_otp = ROTP::TOTP.new(secret).now
        post users_two_factor_setup_path, params: { otp_attempt: valid_otp }
        expect(user.reload.otp_required_for_login).to be true
      end
    end

    context "when código OTP inválido" do
      it "renderiza new com erro" do
        get new_users_two_factor_setup_path
        post users_two_factor_setup_path, params: { otp_attempt: "000000" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /users/two_factor_setup/backup" do
    before do
      user.update!(otp_secret: User.generate_otp_secret, otp_required_for_login: true)
    end

    it "retorna 200 com backup codes" do
      get backup_users_two_factor_setup_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /users/two_factor_setup" do
    before do
      user.update!(otp_secret: User.generate_otp_secret, otp_required_for_login: true)
    end

    it "desativa 2FA e redireciona" do
      delete users_two_factor_setup_path
      expect(user.reload.otp_required_for_login).to be false
    end

    it "redireciona para perfil" do
      delete users_two_factor_setup_path
      expect(response).to redirect_to(edit_user_registration_path)
    end
  end
end
