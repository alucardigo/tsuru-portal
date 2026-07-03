# frozen_string_literal: true

module FiGroup
  # Orquestrador chamado pelo cron (~10min) e pelo botão "Sincronizar agora".
  # Faz o PULL (FI -> Tsuru) a cada ciclo, registra o resultado num FiGroupSyncRun
  # e avisa os admins quando o token cai (recaptura em /admin/figroup). O PUSH
  # (Tsuru -> FI) fica atrás de FIGROUP_PUSH_ENABLED (ver #call).
  class AutoSync
    def initialize(credential = FiGroupCredential.current)
      @credential = credential
    end

    # Roda o ciclo completo de sincronização.
    # @param trigger [String] "cron" | "manual" | "realtime"
    # @return [FiGroupSyncRun, nil] o run criado (nil se o cron estiver desligado)
    def call(trigger: "cron")
      # Cron respeita o interruptor global; manual/realtime sempre roda.
      return nil if trigger == "cron" && !FiGroupSetting.instance.auto_sync_enabled

      run = FiGroupSyncRun.create!(started_at: Time.current, trigger: trigger)

      # Sem credencial válida não há o que sincronizar: avisa e encerra o run.
      if @credential.nil? || !@credential.active?
        notify_token_expired
        run.update!(finished_at: Time.current, token_ok: false, error_details: [ "sem credencial ativa / token expirado" ])
        return run
      end

      begin
        # PULL (FI -> Tsuru): espelha elegibilidade/parecer e vincula. Sempre roda.
        pull = FiGroup::PullSync.new(@credential).call

        # PUSH (Tsuru -> FI): DESLIGADO por padrão. Provamos empiricamente que o
        # PUT /Projects/{id} da API interna do LeidoBem responde 200 mas NÃO
        # persiste conteúdo (teste controlado em clientResponse/objective, ver
        # docs/FIGROUP_API_CONTRATO.md). Enquanto o endpoint de escrita real não
        # for confirmado, o ciclo é pull-only para não gastar chamadas nem
        # reportar envios falsos. Reative com FIGROUP_PUSH_ENABLED=true.
        pushed = 0
        push_errors = []
        if push_enabled?
          push = FiGroup::PushSync.new(@credential).push_all(dry_run: false)
          pushed = push.count { |r| r[:ok] && !r[:skipped] && (r[:diff] || {}).any? }
          push_errors = push.select { |r| r[:error] }.map { |r| "#{r[:code_project]}: #{r[:error]}" }

          # Zera a flag só dos que empurraram sem erro; quem falhou continua
          # pendente para o próximo ciclo (não perde alteração N2 transitória).
          failed_ids = push.select { |r| r[:error] }.map { |r| r[:fi_project_id] }.compact
          cleared = FiGroupProject.where.not(demand_id: nil)
          cleared = cleared.where.not(fi_project_id: failed_ids) if failed_ids.any?
          cleared.update_all(push_pending: false)
        end

        run.update!(
          finished_at: Time.current,
          token_ok: true,
          pulled_count: pull[:projects_synced],
          linked_count: pull[:linked],
          pushed_count: pushed,
          error_details: (pull[:errors] + push_errors)
        )
      rescue FiGroup::AuthError => e
        notify_token_expired
        run.update!(finished_at: Time.current, token_ok: false, error_details: [ "token expirado durante sync: #{e.message}" ])
      rescue StandardError => e
        run.update!(finished_at: Time.current, token_ok: false, error_details: [ "erro inesperado: #{e.class}: #{e.message}" ])
      end

      run
    end

    private

    # Push Tsuru -> FI. Ligado por padrão (o PUT /Projects/{id} persiste desde
    # que o payload omita os campos estruturais — ver FiGroup::Client). Só empurra
    # projeto com diff real. Desligue com FIGROUP_PUSH_ENABLED=false se necessário.
    def push_enabled?
      ENV.fetch("FIGROUP_PUSH_ENABLED", "true").to_s != "false"
    end

    # Avisa os admins que o token caiu, com throttle de 6h para não spammar.
    def notify_token_expired
      setting = FiGroupSetting.instance
      return if setting.last_expiry_notified_at && setting.last_expiry_notified_at > 6.hours.ago

      User.where(role: :admin).each do |u|
        begin
          Notification.create!(
            recipient: u,
            title: "Token FI Group expirou",
            body: "A sincronização automática com o portal LeidoBem parou porque o token expirou. Recapture o token em /admin/figroup para retomar a conversa entre os portais.",
            kind: "automation",
            payload: { figroup: true, event: "token_expired" }
          )
        rescue StandardError => e
          # Falha ao notificar não pode derrubar o sync.
          Rails.logger.warn("[FiGroup::AutoSync] falha ao notificar admin #{u.id}: #{e.message}")
        end
      end

      setting.update!(last_expiry_notified_at: Time.current)
    end
  end
end
