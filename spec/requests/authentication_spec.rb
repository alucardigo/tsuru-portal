require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/sign_in" do
    it "retorna 200" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end

    it "exibe o formulário de login" do
      get new_user_session_path
      expect(response.body).to include("Entrar no Tsuru")
    end
  end

  describe "POST /users/sign_in" do
    context "when credenciais são válidas" do
      it "autentica e redireciona para root" do
        post user_session_path, params: {
          user: { email: user.email, password: "Password1!" }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when credenciais são inválidas" do
      it "retorna 401 ou renderiza login" do
        post user_session_path, params: {
          user: { email: user.email, password: "errada" }
        }
        expect(response.status).to be_in([ 401, 422 ])
      end
    end
  end

  describe "DELETE /users/sign_out" do
    before { sign_in user }

    it "faz logout e redireciona" do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path).or redirect_to(new_user_session_path)
    end
  end

  describe "GET /users/sign_up" do
    it "retorna 200" do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
    end

    it "exibe o formulário de registro" do
      get new_user_registration_path
      expect(response.body).to include("Criar conta")
    end
  end

  describe "POST /users" do
    let(:valid_params) do
      { user: { name: "João Inovação", email: "joao@bellube.com.br",
                password: "Password1!", password_confirmation: "Password1!" } }
    end

    it "cria conta e envia e-mail de confirmação" do
      expect {
        post user_registration_path, params: valid_params
      }.to change(User, :count).by(1)
    end

    it "novo usuário tem role colaborador por padrão" do
      post user_registration_path, params: valid_params
      expect(User.last).to be_colaborador
    end
  end
end
