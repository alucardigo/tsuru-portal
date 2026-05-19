require "rails_helper"

RSpec.describe Demand, type: :model do
  describe "anexos (Active Storage)" do
    subject(:demand) { build(:demand) }

    let(:pdf_blob) do
      { io: StringIO.new("pdf content"), filename: "doc.pdf", content_type: "application/pdf" }
    end
    let(:exe_blob) do
      { io: StringIO.new("exe"), filename: "virus.exe", content_type: "application/x-msdownload" }
    end
    let(:big_blob) do
      { io: StringIO.new("x" * 11.megabytes), filename: "big.pdf", content_type: "application/pdf" }
    end

    it { is_expected.to respond_to(:attachments) }

    it "aceita arquivo PDF válido" do
      demand.save!
      demand.attachments.attach(pdf_blob)
      expect(demand.attachments.count).to eq(1)
    end

    it "valida tamanho máximo de 10MB" do
      demand.save!
      demand.attachments.attach(big_blob)
      demand.valid?
      expect(demand.errors[:attachments]).not_to be_empty
    end

    it "rejeita tipo de conteúdo não permitido" do
      demand.save!
      demand.attachments.attach(exe_blob)
      demand.valid?
      expect(demand.errors[:attachments]).not_to be_empty
    end
  end
end
