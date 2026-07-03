# frozen_string_literal: true

module Admin
  class FigroupController < BaseController
    DEFAULT_COMPANY_ID = "50a51c9b-1afa-41c8-9f4c-494cc8cdf915"
    DEFAULT_SERVICE_IDS = {
      "2023" => "1afc44e6-8c3e-47fc-5457-08dbc6991881",
      "2024" => "f7f0704d-9ece-4b84-4646-08dc32f847a0",
      "2025" => "767d6db7-9d94-411a-6105-08dd49d497fc",
      "2026" => "053c4f53-a374-4c51-f584-08de93d6c24c"
    }.freeze

    def index
      @credential = FiGroupCredential.current
      @projects = FiGroupProject.order(:code_project)
      @figroup_setting = FiGroupSetting.instance
      @last_sync_run   = FiGroupSyncRun.recent(1).first
      @sync_runs       = FiGroupSyncRun.recent(15).to_a
    end

    # Roda um ciclo de sincronização na hora (mesma rotina do cron).
    def sync_now
      run = FiGroup::AutoSync.new.call(trigger: "manual")
      if run&.token_ok
        redirect_to admin_figroup_path,
          notice: "Portais sincronizados: #{run.pulled_count} projeto(s) puxado(s) do FI Group, #{run.linked_count} vinculado(s)."
      else
        redirect_to admin_figroup_path,
          alert: "Não foi possível sincronizar (token expirado?). Recapture o token do portal FI abaixo."
      end
    rescue FiGroup::AuthError
      redirect_to admin_figroup_path,
        alert: "Token FI Group expirado ou ausente — recapture o header Authorization no portal."
    end

    # Liga/desliga o ciclo automático (cron) sem mexer no cron do servidor.
    def toggle_auto_sync
      s = FiGroupSetting.instance
      s.update!(auto_sync_enabled: !s.auto_sync_enabled)
      redirect_to admin_figroup_path,
        notice: "Sincronização automática #{s.auto_sync_enabled ? 'ligada' : 'desligada'}."
    end

    # GET /admin/figroup/capture — página de destino do bookmarklet. Lê o token do
    # #fragmento da URL (client-side, não vai pros logs) e o envia via POST
    # same-origin (capture_save). Só renderiza a view.
    def capture
      render :capture
    end

    # POST /admin/figroup/capture — grava o token capturado na credencial.
    def capture_save
      result = FiGroup::TokenIngest.call(params[:token], captured_by: current_user)
      if result.ok
        render json: { ok: true, expires_at: result.credential.expires_at }
      else
        render json: { ok: false, error: result.error }, status: :unprocessable_entity
      end
    end

    def create_token
      FiGroupCredential.create!(
        token: params[:token].to_s.strip.sub(/\ABearer\s+/i, ""),
        expires_at: Time.current + (params[:expires_in_minutes].presence || 55).to_i.minutes,
        company_id: params[:company_id].presence || DEFAULT_COMPANY_ID,
        base_url: params[:base_url].presence || "https://app.leidobem.com/api/services",
        service_ids: DEFAULT_SERVICE_IDS,
        captured_by: current_user
      )
      redirect_to admin_figroup_path, notice: "Token FI Group capturado. Expira em #{(params[:expires_in_minutes].presence || 55).to_i} min."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_figroup_path, alert: "Falha ao salvar token: #{e.record.errors.full_messages.join(', ')}"
    end

    def pull
      result = FiGroup::PullSync.new.call
      notice = "Sincronização concluída: #{result[:projects_synced]} projeto(s), " \
               "#{result[:linked]} vinculado(s), #{result[:unlinked]} sem vínculo."
      notice += " Erros: #{result[:errors].size}." if result[:errors].present?
      redirect_to admin_figroup_path, notice: notice
    rescue FiGroup::AuthError
      redirect_to admin_figroup_path, alert: "Token FI Group expirado ou ausente — recapture o header Authorization no portal."
    end

    def push
      fp = FiGroupProject.find(params[:id])
      result = FiGroup::PushSync.new.push(fp)
      if result[:skipped]
        redirect_to admin_figroup_path, alert: "Projeto \"#{fp.code_project}\" não tem Demand vinculada — nada enviado."
      elsif result[:diff].blank?
        redirect_to admin_figroup_path, notice: "Projeto \"#{fp.code_project}\" já está sincronizado — nenhuma alteração a enviar."
      else
        redirect_to admin_figroup_path, notice: "Projeto \"#{fp.code_project}\" enviado ao FI Group (#{result[:diff].size} campo(s) atualizado(s))."
      end
    rescue FiGroup::AuthError
      redirect_to admin_figroup_path, alert: "Token FI Group expirado ou ausente — recapture o header Authorization no portal."
    end

    def push_all
      results = FiGroup::PushSync.new.push_all
      pushed = results.count { |r| r[:ok] && r[:diff].present? }
      redirect_to admin_figroup_path, notice: "Push em lote: #{pushed} de #{results.size} projeto(s) vinculado(s) atualizados no FI Group."
    rescue FiGroup::AuthError
      redirect_to admin_figroup_path, alert: "Token FI Group expirado ou ausente — recapture o header Authorization no portal."
    end
  end
end
