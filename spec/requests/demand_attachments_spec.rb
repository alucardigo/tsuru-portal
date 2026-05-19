require "rails_helper"

RSpec.describe "Demand Attachments", type: :request do
  let(:colaborador) { create(:user) }
  let(:demand) { create(:demand, user: colaborador) }
  let(:pdf_file) { fixture_file_upload("spec/fixtures/files/sample.pdf", "application/pdf") }
  let(:exe_file) { fixture_file_upload("spec/fixtures/files/sample.exe", "application/x-msdownload") }
  let(:base_params) { { title: demand.title, description: demand.description } }

  before { sign_in colaborador }

  describe "PATCH /demands/:id com arquivo" do
    it "anexa PDF válido à demanda" do
      patch demand_path(demand), params: { demand: base_params.merge(attachments: [ pdf_file ]) }
      expect(demand.reload.attachments).to be_attached
    end

    it "rejeita arquivo com tipo inválido" do
      patch demand_path(demand), params: { demand: base_params.merge(attachments: [ exe_file ]) }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /demands/:id/attachments/:attachment_id" do
    before do
      demand.attachments.attach(
        io: StringIO.new("pdf"), filename: "doc.pdf", content_type: "application/pdf"
      )
    end

    it "remove anexo quando dono da demanda" do
      attachment_id = demand.attachments.first.id
      delete demand_attachment_path(demand, attachment_id)
      expect(demand.reload.attachments.count).to eq(0)
    end
  end
end
