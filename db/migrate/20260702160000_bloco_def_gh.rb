class BlocoDefGh < ActiveRecord::Migration[8.1]
  def change
    # === Bloco D — Composição de defesa N3 + Evidências ===
    create_table :defense_dossiers do |t|
      t.references :demand, null: false, foreign_key: true, index: true
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.integer  :ano_base, null: false
      t.string   :status, null: false, default: "rascunho" # rascunho | final
      t.jsonb    :success_criteria, null: false, default: [] # Bloco 1 — [{criterio, meta, resultado, status}]
      t.text     :ganhos_operacionais                # Bloco 2
      t.text     :barreiras_base                     # Bloco 3.1.1
      t.text     :barreiras_emergentes                # Bloco 3.1.2
      t.text     :barreiras_resolvidas                # Bloco 3.2.2
      t.text     :barreiras_nao_resolvidas             # Bloco 3.2.2
      t.text     :contexto_plurianual                 # Bloco 4
      t.string   :recomendacao_final                  # solido | riscos_pontuais | fragil | reescrever
      t.text     :recomendacao_notas
      t.timestamps
      t.index [ :demand_id, :ano_base ], unique: true, name: "idx_defense_dossiers_demand_ano"
    end

    create_table :defense_evidences do |t|
      t.references :defense_dossier, null: false, foreign_key: true, index: true
      t.string   :tipo, null: false # relatorio_tecnico, poc_logs, timesheet, contrato_st, patente, publicacao, outro
      t.string   :descricao, null: false
      t.timestamps
    end

    # === Bloco F — Biblioteca PD&I ===
    create_table :knowledge_articles do |t|
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.string  :title, null: false, limit: 200
      t.string  :category, null: false # legislacao, calculo, dispendios, formpd, contestacao, glossario, outro
      t.text    :body, null: false
      t.boolean :published, null: false, default: true
      t.timestamps
    end

    # === Bloco G — Relatórios de IA ===
    create_table :ai_reports do |t|
      t.references :demand, null: true, foreign_key: true, index: true # nil = relatório de portfólio
      t.references :requested_by, null: true, foreign_key: { to_table: :users }
      t.references :llm_provider, null: true, foreign_key: true
      t.string   :kind, null: false # project_summary | portfolio_insight | weekly_digest
      t.string   :status, null: false, default: "pending" # pending | ok | failed
      t.text     :content
      t.text     :error
      t.timestamps
    end

    # === Bloco H — Automações Power Automate ===
    add_column :task_automations, :webhook_url, :string
    add_column :task_automations, :subject_scope, :string, null: false, default: "task" # task | demand
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true
  end
end
