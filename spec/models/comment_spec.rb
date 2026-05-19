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
end
