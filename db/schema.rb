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

ActiveRecord::Schema[8.1].define(version: 2026_05_20_145633) do
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

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "demand_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["demand_id"], name: "index_comments_on_demand_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
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
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.jsonb "n1_flags", default: {}, null: false
    t.jsonb "n2_assessment", default: {}
    t.integer "ods_goals", default: [], array: true
    t.text "parecer_tecnico"
    t.text "solucao_proposta"
    t.string "title", null: false
    t.integer "trl"
    t.datetime "updated_at", null: false
    t.string "urgencia"
    t.bigint "user_id", null: false
    t.index ["aasm_state"], name: "index_demands_on_aasm_state"
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
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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
  add_foreign_key "comments", "demands"
  add_foreign_key "comments", "users"
  add_foreign_key "demand_transitions", "demands"
  add_foreign_key "demand_transitions", "users", column: "actor_id"
  add_foreign_key "demands", "users"
  add_foreign_key "expenses", "lei_do_bem_records"
  add_foreign_key "lei_do_bem_records", "demands"
  add_foreign_key "partnerships", "lei_do_bem_records"
  add_foreign_key "team_members", "lei_do_bem_records"
  add_foreign_key "team_members", "users"
end
