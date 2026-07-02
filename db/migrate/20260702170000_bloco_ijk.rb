class BlocoIjk < ActiveRecord::Migration[8.1]
  def change
    # === Bloco K — Converter demanda em tarefa de projeto existente ===
    add_reference :demands, :converted_task, null: true, foreign_key: { to_table: :project_tasks }, index: true
    add_column :demands, :conversion_note, :text

    # === Bloco I — Preparação integração Sankhya ===
    create_table :sankhya_mappings do |t|
      t.string  :kind, null: false # colaborador | parceiro_pj | projeto | nota_servico
      t.string  :entidade_sankhya, null: false # rootEntity no gateway Sankhya (ex: TGFPAR)
      t.string  :campo_codigo, null: false, default: "CODIGO"
      t.string  :campo_nome, null: false, default: "NOME"
      t.string  :campos_extra # lista separada por vírgula de campos adicionais a sincronizar
      t.text    :criterio # expressão de filtro Sankhya (ex: this.CLASSIFICACAO = 'PJ')
      t.boolean :enabled, null: false, default: true
      t.datetime :last_synced_at
      t.integer :last_sync_count
      t.text    :last_sync_error
      t.timestamps
      t.index :kind, unique: true
    end

    create_table :sankhya_records do |t|
      t.references :sankhya_mapping, null: false, foreign_key: true, index: true
      t.string   :codigo, null: false
      t.string   :nome
      t.jsonb    :raw_data, null: false, default: {}
      t.datetime :synced_at
      t.timestamps
      t.index [ :sankhya_mapping_id, :codigo ], unique: true, name: "idx_sankhya_records_mapping_codigo"
    end

    add_reference :users, :sankhya_record, null: true, foreign_key: { to_table: :sankhya_records }, index: true
    add_reference :demands, :sankhya_record, null: true, foreign_key: { to_table: :sankhya_records }, index: true
  end
end
