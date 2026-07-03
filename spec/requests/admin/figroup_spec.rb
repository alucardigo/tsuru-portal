require "rails_helper"

# Specs de request para o painel /admin/figroup.
# NÃO batem na API real do LeidoBem: o index apenas lê o banco e o POST de token
# só persiste uma FiGroupCredential. Pull/push (que fariam HTTP) são stubbados
# via instance_double quando exercitados.
RSpec.describe "Admin::Figroup", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:colaborador) { create(:user) }

  describe "GET /admin/figroup" do
    context "quando o usuário é colaborador (não admin)" do
      before { sign_in colaborador }

      it "nega acesso (forbidden / redirect para root)" do
        get admin_figroup_path
        expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
      end

      it "não expõe o painel" do
        get admin_figroup_path
        expect(response).not_to have_http_status(:ok)
      end
    end

    context "quando o usuário é admin" do
      before { sign_in admin }

      it "retorna 200" do
        get admin_figroup_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /admin/figroup/token" do
    context "como admin" do
      before { sign_in admin }

      it "cria uma FiGroupCredential" do
        expect {
          post admin_figroup_token_path, params: { token: "jwt-capturado" }
        }.to change(FiGroupCredential, :count).by(1)
      end

      it "armazena o token e marca captured_by como o admin atual" do
        post admin_figroup_token_path, params: { token: "jwt-capturado" }

        cred = FiGroupCredential.order(:created_at).last
        expect(cred.token).to eq("jwt-capturado")
        expect(cred.captured_by_id).to eq(admin.id)
      end

      it "define expires_at no futuro a partir de expires_in_minutes" do
        post admin_figroup_token_path,
             params: { token: "jwt-capturado", expires_in_minutes: 30 }

        cred = FiGroupCredential.order(:created_at).last
        expect(cred.expires_at).to be_within(30.seconds).of(30.minutes.from_now)
        expect(cred).to be_active
      end

      it "usa 55 minutos como padrão quando expires_in_minutes não é informado" do
        post admin_figroup_token_path, params: { token: "jwt-capturado" }

        cred = FiGroupCredential.order(:created_at).last
        expect(cred.expires_at).to be_within(30.seconds).of(55.minutes.from_now)
      end

      it "redireciona de volta para o painel com flash" do
        post admin_figroup_token_path, params: { token: "jwt-capturado" }
        expect(response).to redirect_to(admin_figroup_path)
        expect(flash[:notice] || flash[:alert]).to be_present
      end
    end

    context "como colaborador" do
      before { sign_in colaborador }

      it "não cria credencial" do
        expect {
          post admin_figroup_token_path, params: { token: "x" }
        }.not_to change(FiGroupCredential, :count)
      end
    end
  end

  describe "POST /admin/figroup/pull" do
    before { sign_in admin }

    it "invoca PullSync e informa as contagens em flash" do
      fake = instance_double(
        FiGroup::PullSync,
        call: { projects_synced: 3, linked: 2, unlinked: 1, errors: [] }
      )
      allow(FiGroup::PullSync).to receive(:new).and_return(fake)

      post admin_figroup_pull_path

      expect(fake).to have_received(:call)
      expect(response).to redirect_to(admin_figroup_path)
      expect(flash[:notice]).to be_present
    end

    it "avisa para recapturar o token quando expirado (AuthError)" do
      fake = instance_double(FiGroup::PullSync)
      allow(fake).to receive(:call).and_raise(FiGroup::AuthError, "token expirado")
      allow(FiGroup::PullSync).to receive(:new).and_return(fake)

      post admin_figroup_pull_path

      expect(response).to redirect_to(admin_figroup_path)
      expect(flash[:alert]).to be_present
    end
  end
end
