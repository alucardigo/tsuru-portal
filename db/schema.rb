# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_03_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_reports", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "demand_id"
    t.text "error"
    t.string "kind", null: false
    t.bigint "llm_provider_id"
    t.bigint "requested_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["demand_id"], name: "index_ai_reports_on_demand_id"
    t.index ["llm_provider_id"], name: "index_ai_reports_on_llm_provider_id"
    t.index ["requested_by_id"], name: "index_ai_reports_on_requested_by_id"
  end

  create_table "areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 80, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_areas_on_name", unique: true
  end

  create_table "board_decisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "decider_id", null: false
    t.bigint "demand_id", null: false
    t.decimal "estimated_benefit", precision: 14, scale: 2
    t.text "justification", null: false
    t.string "outcome", null: false
    t.datetime "updated_at", null: false
    t.index ["decider_id"], name: "index_board_decisions_on_decider_id"
    t.index ["demand_id"], name: "index_board_decisions_on_demand_id"
    t.index ["outcome"], name: "index_board_decisions_on_outcome"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "demand_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["demand_id"], name: "index_comments_on_demand_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "defense_dossiers", force: :cascade do |t|
    t.integer "ano_base", null: false
    t.text "barreiras_base"
    t.text "barreiras_emergentes"
    t.text "barreiras_nao_resolvidas"
    t.text "barreiras_resolvidas"
    t.text "contexto_plurianual"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "demand_id", null: false
    t.text "ganhos_operacionais"
    t.string "recomendacao_final"
    t.text "recomendacao_notas"
    t.string "status", default: "rascunho", null: false
    t.jsonb "success_criteria", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_defense_dossiers_on_created_by_id"
    t.index ["demand_id", "ano_base"], name: "idx_defense_dossiers_demand_ano", unique: true
    t.index ["demand_id"], name: "index_defense_dossiers_on_demand_id"
  end

  create_table "defense_evidences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "defense_dossier_id", null: false
    t.string "descricao", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.index ["defense_dossier_id"], name: "index_defense_evidences_on_defense_dossier_id"
  end

  create_table "demand_transitions", force: :cascade do |t|
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.bigint "demand_id", null: false
    t.string "event", null: false
    t.string "from_state"
    t.text "justification"
    t.string "to_state", null: false
    t.index ["actor_id"], name: "index_demand_transitions_on_actor_id"
    t.index ["demand_id", "created_at"], name: "index_demand_transitions_on_demand_id_and_created_at"
    t.index ["demand_id"], name: "index_demand_transitions_on_demand_id"
  end

  create_table "demands", force: :cascade do |t|
    t.string "aasm_state", default: "rascunho", null: false
    t.string "area_impactada"
    t.string "codigo"
    t.text "conversion_note"
    t.bigint "converted_task_id"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.jsonb "n1_flags", default: {}, null: false
    t.jsonb "n2_assessment", default: {}
    t.integer "numero_inova"
    t.integer "ods_goals", default: [], array: true
    t.text "parecer_tecnico"
    t.bigint "sankhya_record_id"
    t.text "solucao_proposta"
    t.jsonb "task_field_definitions", default: [], null: false
    t.jsonb "task_workflow_states", default: [], null: false
    t.string "title", null: false
    t.integer "trl"
    t.datetime "updated_at", null: false
    t.string "urgencia"
    t.bigint "user_id", null: false
    t.index ["aasm_state"], name: "index_demands_on_aasm_state"
    t.index ["codigo"], name: "index_demands_on_codigo", unique: true
    t.index ["converted_task_id"], name: "index_demands_on_converted_task_id"
    t.index ["numero_inova"], name: "index_demands_on_numero_inova", unique: true
    t.index ["sankhya_record_id"], name: "index_demands_on_sankhya_record_id"
    t.index ["user_id"], name: "index_demands_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "categoria", null: false
    t.string "centro_resultado_sankhya"
    t.datetime "created_at", null: false
    t.date "data_competencia", null: false
    t.string "descricao", null: false
    t.string "documento_fiscal"
    t.bigint "lei_do_bem_record_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 14, scale: 2, null: false
    t.index ["categoria"], name: "index_expenses_on_categoria"
    t.index ["data_competencia"], name: "index_expenses_on_data_competencia"
    t.index ["lei_do_bem_record_id"], name: "index_expenses_on_lei_do_bem_record_id"
  end

  create_table "figroup_credentials", force: :cascade do |t|
    t.string "base_url", default: "https://app.leidobem.com/api/services"
    t.bigint "captured_by_id"
    t.string "company_id"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.jsonb "service_ids"
    t.text "token"
    t.datetime "updated_at", null: false
    t.index ["captured_by_id"], name: "index_figroup_credentials_on_captured_by_id"
  end

  create_table "figroup_projects", force: :cascade do |t|
    t.text "client_response"
    t.string "code_project"
    t.datetime "created_at", null: false
    t.bigint "demand_id"
    t.integer "eligibility"
    t.text "explanation_fi"
    t.string "fi_project_id"
    t.integer "fiscal_year"
    t.datetime "last_pulled_at"
    t.datetime "last_pushed_at"
    t.string "name"
    t.text "position_fi"
    t.boolean "push_pending", default: false, null: false
    t.jsonb "raw", default: {}
    t.string "service_id"
    t.datetime "updated_at", null: false
    t.index ["demand_id"], name: "index_figroup_projects_on_demand_id"
    t.index ["fi_project_id"], name: "index_figroup_projects_on_fi_project_id", unique: true
    t.index ["push_pending"], name: "index_figroup_projects_on_push_pending"
  end

  create_table "figroup_settings", force: :cascade do |t|
    t.boolean "auto_sync_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "last_expiry_notified_at"
    t.datetime "updated_at", null: false
  end

  create_table "figroup_sync_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "error_details", default: []
    t.datetime "finished_at"
    t.integer "linked_count", default: 0
    t.integer "pulled_count", default: 0
    t.integer "pushed_count", default: 0
    t.datetime "started_at"
    t.boolean "token_ok", default: false
    t.string "trigger", default: "cron"
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_figroup_sync_runs_on_started_at"
  end

  create_table "knowledge_articles", force: :cascade do |t|
    t.text "body", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "published", default: true, null: false
    t.string "title", limit: 200, null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_knowledge_articles_on_created_by_id"
  end

  create_table "lei_do_bem_records", force: :cascade do |t|
    t.integer "ano_base", null: false
    t.boolean "base_zero_pesquisadores", default: false
    t.decimal "beneficio_estimado", precision: 14, scale: 2
    t.datetime "created_at", null: false
    t.bigint "demand_id", null: false
    t.string "natureza_projeto", null: false
    t.text "ods_projeto", default: [], array: true
    t.text "parecer_consolidado"
    t.string "regime_tributacao", default: "lucro_real_anual"
    t.boolean "tem_patente", default: false
    t.decimal "total_dispendios", precision: 14, scale: 2, default: "0.0"
    t.integer "trl_final"
    t.integer "trl_inicial"
    t.datetime "updated_at", null: false
    t.index ["ano_base"], name: "index_lei_do_bem_records_on_ano_base"
    t.index ["demand_id"], name: "index_lei_do_bem_records_on_demand_id", unique: true
  end

  create_table "llm_providers", force: :cascade do |t|
    t.text "api_key"
    t.string "base_url"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "kind", limit: 20, null: false
    t.string "model", limit: 120, null: false
    t.string "name", limit: 80, null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_llm_providers_on_enabled"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "demand_id"
    t.string "kind", null: false
    t.jsonb "payload", default: {}
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["demand_id"], name: "index_notifications_on_demand_id"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "partnerships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "data_fim"
    t.date "data_inicio"
    t.text "descricao_parceria"
    t.string "ict_cnpj"
    t.string "ict_nome", null: false
    t.bigint "lei_do_bem_record_id", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_contrato", precision: 14, scale: 2
    t.index ["lei_do_bem_record_id"], name: "index_partnerships_on_lei_do_bem_record_id"
  end

  create_table "project_task_assignees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_task_id", "user_id"], name: "idx_pta_unique", unique: true
    t.index ["project_task_id"], name: "index_project_task_assignees_on_project_task_id"
    t.index ["user_id"], name: "index_project_task_assignees_on_user_id"
  end

  create_table "project_task_checklist_items", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.boolean "done", default: false, null: false
    t.integer "position", default: 0, null: false
    t.bigint "project_task_id", null: false
    t.string "title", limit: 200, null: false
    t.datetime "updated_at", null: false
    t.index ["project_task_id", "position"], name: "idx_on_project_task_id_position_a995e5e6ff"
    t.index ["project_task_id"], name: "index_project_task_checklist_items_on_project_task_id"
  end

  create_table "project_task_comment_reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", limit: 8, null: false
    t.bigint "project_task_comment_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_task_comment_id", "user_id", "emoji"], name: "idx_ptcr_unique", unique: true
    t.index ["project_task_comment_id"], name: "idx_ptcr_comment"
    t.index ["user_id"], name: "idx_ptcr_user"
  end

  create_table "project_task_comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "project_task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_task_id", "created_at"], name: "index_project_task_comments_on_project_task_id_and_created_at"
    t.index ["project_task_id"], name: "index_project_task_comments_on_project_task_id"
    t.index ["user_id"], name: "index_project_task_comments_on_user_id"
  end

  create_table "project_task_dependencies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", limit: 32, default: "finish_to_start", null: false
    t.bigint "predecessor_id", null: false
    t.bigint "successor_id", null: false
    t.datetime "updated_at", null: false
    t.index ["predecessor_id", "successor_id"], name: "idx_task_deps_unique", unique: true
    t.index ["predecessor_id"], name: "index_project_task_dependencies_on_predecessor_id"
    t.index ["successor_id"], name: "index_project_task_dependencies_on_successor_id"
  end

  create_table "project_task_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_task_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_task_id", "tag_id"], name: "idx_ptt_unique", unique: true
    t.index ["project_task_id"], name: "index_project_task_tags_on_project_task_id"
    t.index ["tag_id"], name: "index_project_task_tags_on_tag_id"
  end

  create_table "project_task_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "demand_id", null: false
    t.string "name", limit: 100, null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["demand_id"], name: "index_project_task_templates_on_demand_id"
  end

  create_table "project_task_time_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.datetime "ended_at"
    t.bigint "project_task_id", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_task_id"], name: "index_project_task_time_entries_on_project_task_id"
    t.index ["user_id", "ended_at"], name: "index_project_task_time_entries_on_user_id_and_ended_at"
    t.index ["user_id"], name: "index_project_task_time_entries_on_user_id"
  end

  create_table "project_task_watchers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_task_id", "user_id"], name: "idx_task_watchers_unique", unique: true
    t.index ["project_task_id"], name: "index_project_task_watchers_on_project_task_id"
    t.index ["user_id"], name: "index_project_task_watchers_on_user_id"
  end

  create_table "project_tasks", force: :cascade do |t|
    t.datetime "assigned_at"
    t.bigint "assignee_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.jsonb "custom_fields", default: {}, null: false
    t.bigint "demand_id", null: false
    t.text "description"
    t.date "due_date"
    t.decimal "estimated_hours", precision: 8, scale: 2
    t.string "kanban_status", default: "backlog", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "prev_kanban_status", limit: 32
    t.string "priority", default: "media", null: false
    t.jsonb "recurrence"
    t.decimal "spent_hours", precision: 8, scale: 2, default: "0.0", null: false
    t.bigint "sprint_id"
    t.datetime "started_at"
    t.integer "story_points"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_project_tasks_on_assignee_id"
    t.index ["creator_id"], name: "index_project_tasks_on_creator_id"
    t.index ["custom_fields"], name: "index_project_tasks_on_custom_fields", using: :gin
    t.index ["demand_id", "kanban_status", "position"], name: "index_project_tasks_kanban_order"
    t.index ["demand_id"], name: "index_project_tasks_on_demand_id"
    t.index ["kanban_status"], name: "index_project_tasks_on_kanban_status"
    t.index ["parent_id"], name: "index_project_tasks_on_parent_id"
    t.index ["sprint_id"], name: "index_project_tasks_on_sprint_id"
  end

  create_table "sankhya_mappings", force: :cascade do |t|
    t.string "campo_codigo", default: "CODIGO", null: false
    t.string "campo_nome", default: "NOME", null: false
    t.string "campos_extra"
    t.datetime "created_at", null: false
    t.text "criterio"
    t.boolean "enabled", default: true, null: false
    t.string "entidade_sankhya", null: false
    t.string "kind", null: false
    t.integer "last_sync_count"
    t.text "last_sync_error"
    t.datetime "last_synced_at"
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_sankhya_mappings_on_kind", unique: true
  end

  create_table "sankhya_records", force: :cascade do |t|
    t.string "codigo", null: false
    t.datetime "created_at", null: false
    t.string "nome"
    t.jsonb "raw_data", default: {}, null: false
    t.bigint "sankhya_mapping_id", null: false
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["sankhya_mapping_id", "codigo"], name: "idx_sankhya_records_mapping_codigo", unique: true
    t.index ["sankhya_mapping_id"], name: "index_sankhya_records_on_sankhya_mapping_id"
  end

  create_table "saved_task_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "demand_id"
    t.jsonb "filters", default: {}, null: false
    t.string "name", limit: 80, null: false
    t.boolean "shared", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "view_kind", limit: 20, default: "kanban", null: false
    t.index ["demand_id"], name: "index_saved_task_views_on_demand_id"
    t.index ["user_id"], name: "index_saved_task_views_on_user_id"
  end

  create_table "sprints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "demand_id", null: false
    t.date "end_date"
    t.text "goal"
    t.string "name", limit: 80, null: false
    t.date "start_date"
    t.string "state", limit: 20, default: "planejado", null: false
    t.datetime "updated_at", null: false
    t.index ["demand_id", "state"], name: "index_sprints_on_demand_id_and_state"
    t.index ["demand_id"], name: "index_sprints_on_demand_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color", limit: 16, default: "gray", null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 60, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "task_automations", force: :cascade do |t|
    t.jsonb "action", default: {}, null: false
    t.jsonb "condition", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "demand_id"
    t.boolean "enabled", default: true, null: false
    t.string "name", limit: 120, null: false
    t.string "subject_scope", default: "task", null: false
    t.string "trigger_event", limit: 60, null: false
    t.datetime "updated_at", null: false
    t.string "webhook_url"
    t.index ["demand_id"], name: "index_task_automations_on_demand_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.boolean "contratado_no_ano_base", default: false
    t.string "cpf"
    t.datetime "created_at", null: false
    t.decimal "custo_anual", precision: 14, scale: 2
    t.boolean "dedicacao_exclusiva", default: false
    t.decimal "dedicacao_percentual", precision: 5, scale: 2
    t.decimal "horas_anuais", precision: 8, scale: 2
    t.bigint "lei_do_bem_record_id", null: false
    t.string "nome", null: false
    t.string "titulacao"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "vinculo"
    t.index ["lei_do_bem_record_id"], name: "index_team_members_on_lei_do_bem_record_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "api_token"
    t.string "area"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.integer "consumed_timestep"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.bigint "sankhya_record_id"
    t.bigint "supervisor_id"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["sankhya_record_id"], name: "index_users_on_sankhya_record_id"
    t.index ["supervisor_id"], name: "index_users_on_supervisor_id"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_reports", "demands"
  add_foreign_key "ai_reports", "llm_providers"
  add_foreign_key "ai_reports", "users", column: "requested_by_id"
  add_foreign_key "board_decisions", "demands"
  add_foreign_key "board_decisions", "users", column: "decider_id"
  add_foreign_key "comments", "demands"
  add_foreign_key "comments", "users"
  add_foreign_key "defense_dossiers", "demands"
  add_foreign_key "defense_dossiers", "users", column: "created_by_id"
  add_foreign_key "defense_evidences", "defense_dossiers"
  add_foreign_key "demand_transitions", "demands"
  add_foreign_key "demand_transitions", "users", column: "actor_id"
  add_foreign_key "demands", "project_tasks", column: "converted_task_id"
  add_foreign_key "demands", "sankhya_records"
  add_foreign_key "demands", "users"
  add_foreign_key "expenses", "lei_do_bem_records"
  add_foreign_key "figroup_credentials", "users", column: "captured_by_id"
  add_foreign_key "figroup_projects", "demands"
  add_foreign_key "knowledge_articles", "users", column: "created_by_id"
  add_foreign_key "lei_do_bem_records", "demands"
  add_foreign_key "notifications", "demands"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "partnerships", "lei_do_bem_records"
  add_foreign_key "project_task_assignees", "project_tasks"
  add_foreign_key "project_task_assignees", "users"
  add_foreign_key "project_task_checklist_items", "project_tasks"
  add_foreign_key "project_task_comment_reactions", "project_task_comments"
  add_foreign_key "project_task_comment_reactions", "users"
  add_foreign_key "project_task_comments", "project_tasks"
  add_foreign_key "project_task_comments", "users"
  add_foreign_key "project_task_dependencies", "project_tasks", column: "predecessor_id"
  add_foreign_key "project_task_dependencies", "project_tasks", column: "successor_id"
  add_foreign_key "project_task_tags", "project_tasks"
  add_foreign_key "project_task_tags", "tags"
  add_foreign_key "project_task_templates", "demands"
  add_foreign_key "project_task_time_entries", "project_tasks"
  add_foreign_key "project_task_time_entries", "users"
  add_foreign_key "project_task_watchers", "project_tasks"
  add_foreign_key "project_task_watchers", "users"
  add_foreign_key "project_tasks", "demands"
  add_foreign_key "project_tasks", "project_tasks", column: "parent_id"
  add_foreign_key "project_tasks", "sprints"
  add_foreign_key "project_tasks", "users", column: "assignee_id"
  add_foreign_key "project_tasks", "users", column: "creator_id"
  add_foreign_key "sankhya_records", "sankhya_mappings"
  add_foreign_key "saved_task_views", "demands"
  add_foreign_key "saved_task_views", "users"
  add_foreign_key "sprints", "demands"
  add_foreign_key "task_automations", "demands"
  add_foreign_key "team_members", "lei_do_bem_records"
  add_foreign_key "team_members", "users"
  add_foreign_key "users", "sankhya_records"
  add_foreign_key "users", "users", column: "supervisor_id"
end
