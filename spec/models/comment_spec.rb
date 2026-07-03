require "rails_helper"

RSpec.describe Comment, type: :model do
  subject(:comment) { build(:comment) }

  describe "validações" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:demand) }
  end

  describe "imutabilidade (append-only)" do
    let(:comment) { create(:comment) }

    it "não pode ser alterado após criação" do
      comment.body = "texto modificado"
      expect(comment).not_to be_valid
    end

    it "adiciona erro de imutabilidade na base" do
      comment.body = "texto modificado"
      comment.valid?
      expect(comment.errors[:base]).to include(a_string_matching(/imutável/i))
    end
  end

  describe "PaperTrail" do
    it { is_expected.to be_a(PaperTrail::Model::InstanceMethods) }
  end

  describe "#mentioned_users" do
    it "retorna uma relação vazia (não um Array) quando não há menções" do
      comment = build(:comment, body: "comentário sem nenhuma menção")
      expect(comment.mentioned_users).to eq(User.none)
    end

    it "encontra usuário mencionado por e-mail local" do
      mencionado = create(:user, email: "fulano@bellube.com.br")
      comment = build(:comment, body: "olá @fulano, dá uma olhada")
      expect(comment.mentioned_users).to include(mencionado)
    end
  end

  describe "#notify_mentions" do
    it "não estoura quando o comentário não tem menções (regressão do bug .where em Array)" do
      demand = create(:demand)
      expect {
        create(:comment, demand: demand, body: "comentário sem menção nenhuma")
      }.not_to raise_error
    end

    it "cria notificação para o usuário mencionado" do
      autor = create(:user, email: "autor@bellube.com.br")
      mencionado = create(:user, email: "fulano@bellube.com.br")
      demand = create(:demand)

      expect {
        create(:comment, demand: demand, user: autor, body: "olá @fulano, comenta aí @autor")
      }.to change { Notification.where(recipient_id: mencionado.id, kind: "mention").count }.by(1)
    end

    it "não notifica o próprio autor do comentário" do
      autor = create(:user, email: "autor@bellube.com.br")
      create(:user, email: "fulano@bellube.com.br")
      demand = create(:demand)

      expect {
        create(:comment, demand: demand, user: autor, body: "olá @fulano, comenta aí @autor")
      }.not_to change { Notification.where(recipient_id: autor.id, kind: "mention").count }
    end
  end
end
