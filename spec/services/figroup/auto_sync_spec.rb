require "rails_helper"

RSpec.describe FiGroup::AutoSync, type: :service do
  # Nunca faz HTTP real: PullSync/PushSync são stubados por instância.
  before do
    allow_any_instance_of(FiGroup::PullSync)
      .to receive(:call)
      .and_return({ projects_synced: 2, linked: 2, unlinked: 0, errors: [] })

    allow_any_instance_of(FiGroup::PushSync)
      .to receive(:push_all)
      .and_return([ { ok: true, diff: { "name" => {} }, skipped: false, code_project: "X" } ])
  end

  def credencial_valida!
    FiGroupCredential.create!(token: "jwt", expires_at: 1.hour.from_now, service_ids: { "2026" => "sid" })
  end

  describe "#call com token válido (push ligado por padrão)" do
    it "registra um FiGroupSyncRun token_ok e conta pull + push" do
      credencial_valida!

      run = nil
      expect { run = described_class.new.call(trigger: "cron") }
        .to change(FiGroupSyncRun, :count).by(1)

      expect(run.token_ok).to be(true)
      expect(run.pulled_count).to eq(2)
      expect(run.linked_count).to eq(2)
      # Push ligado por padrão: o stub de push_all devolve 1 projeto com diff.
      expect(run.pushed_count).to eq(1)
      # error_details: coluna JSONB (errors é reservado por ActiveModel).
      expect(Array(run.error_details)).to be_empty
      expect(run.finished_at).to be_present
    end
  end

  describe "#call com FIGROUP_PUSH_ENABLED=false" do
    around do |ex|
      original = ENV["FIGROUP_PUSH_ENABLED"]
      ENV["FIGROUP_PUSH_ENABLED"] = "false"
      ex.run
      ENV["FIGROUP_PUSH_ENABLED"] = original
    end

    it "faz apenas o pull; pushed_count fica 0" do
      credencial_valida!

      run = described_class.new.call(trigger: "cron")

      expect(run.token_ok).to be(true)
      expect(run.pushed_count).to eq(0)
    end
  end

  describe "#call sem credencial ativa" do
    it "marca o run token_ok=false e notifica um admin" do
      admin = create(:user, :admin)

      run = nil
      expect { run = described_class.new.call(trigger: "cron") }
        .to change(FiGroupSyncRun, :count).by(1)

      expect(run.token_ok).to be(false)
      expect(Array(run.error_details)).to be_present

      notif = Notification.where(recipient: admin, kind: "automation").last
      expect(notif).to be_present
      expect(notif.title).to match(/token/i)
    end
  end

  describe "#call quando o pull levanta AuthError" do
    it "não propaga: persiste o run com token_ok=false" do
      credencial_valida!
      # O pull sempre roda no ciclo (o push é opcional); um AuthError aqui é o
      # caso realista de token que expirou entre a checagem e a chamada.
      allow_any_instance_of(FiGroup::PullSync)
        .to receive(:call)
        .and_raise(FiGroup::AuthError)

      run = nil
      expect { run = described_class.new.call(trigger: "cron") }
        .to change(FiGroupSyncRun, :count).by(1)

      expect(run).to be_persisted
      expect(run.token_ok).to be(false)
      expect(Array(run.error_details)).to be_present
    end
  end

  describe "#call com auto_sync desligado e trigger cron" do
    it "não roda nada e retorna nil" do
      FiGroupSetting.instance.update!(auto_sync_enabled: false)

      result = nil
      expect { result = described_class.new.call(trigger: "cron") }
        .not_to change(FiGroupSyncRun, :count)

      expect(result).to be_nil
    end
  end
end
