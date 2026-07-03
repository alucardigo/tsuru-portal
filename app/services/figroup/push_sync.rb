# frozen_string_literal: true

module FiGroup
  # Empurra os campos N2 do Tsuru (Demand) de volta para o LeidoBem (FI Group).
  #
  # Fluxo por projeto:
  #   - GET do projeto atual (client.project(fi_id));
  #   - monta o payload sobrescrevendo os campos do Tsuru presentes
  #     (FieldMap.apply_tsuru_onto_fi);
  #   - calcula o diff (FieldMap.diff);
  #   - se nao for dry_run e houver diff, faz o PUT e atualiza last_pushed_at.
  class PushSync
    def initialize(credential = FiGroupCredential.current)
      @credential = credential
      @client = FiGroup::Client.new(@credential)
    end

    # Empurra um unico FiGroupProject.
    # @return [Hash] { ok:, diff:, skipped: }
    def push(figroup_project, dry_run: false)
      demand = figroup_project.demand
      return { ok: false, diff: {}, skipped: true } if demand.nil?

      fi_id = figroup_project.fi_project_id
      current = @client.project(fi_id)

      payload = FiGroup::FieldMap.apply_tsuru_onto_fi(current, demand)
      diff = FiGroup::FieldMap.diff(current, demand)

      if !dry_run && diff.present?
        @client.update_project(fi_id, payload)
        figroup_project.update!(last_pushed_at: Time.current)
      end

      { ok: true, diff: diff, skipped: false }
    end

    # Empurra todos os FiGroupProject vinculados a alguma Demand.
    # Erros por projeto sao capturados sem abortar o lote (AuthError propaga).
    # @return [Array<Hash>] um resultado por projeto
    def push_all(dry_run: false)
      results = []

      FiGroupProject.where.not(demand_id: nil).find_each do |fp|
        begin
          results << push(fp, dry_run: dry_run).merge(
            fi_project_id: fp.fi_project_id,
            code_project: fp.code_project
          )
        rescue FiGroup::AuthError
          raise
        rescue StandardError => e
          results << {
            ok: false,
            diff: {},
            skipped: false,
            error: e.message,
            fi_project_id: fp.fi_project_id,
            code_project: fp.code_project
          }
        end
      end

      results
    end
  end
end
