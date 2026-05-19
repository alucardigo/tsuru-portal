class CreateLeiDoBemTables < ActiveRecord::Migration[8.1]
  def change
    create_table :lei_do_bem_records do |t|
      t.references :demand, null: false, foreign_key: true, index: { unique: true }
      t.integer :ano_base, null: false
      t.string :natureza_projeto, null: false
      t.integer :trl_inicial
      t.integer :trl_final
      t.text :ods_projeto, array: true, default: []
      t.decimal :total_dispendios, precision: 14, scale: 2, default: 0
      t.decimal :beneficio_estimado, precision: 14, scale: 2
      t.boolean :tem_patente, default: false
      t.boolean :base_zero_pesquisadores, default: false
      t.string :regime_tributacao, default: "lucro_real_anual"
      t.text :parecer_consolidado
      t.timestamps
    end
    add_index :lei_do_bem_records, :ano_base

    create_table :expenses do |t|
      t.references :lei_do_bem_record, null: false, foreign_key: true
      t.string :categoria, null: false
      t.string :descricao, null: false
      t.decimal :valor, precision: 14, scale: 2, null: false
      t.date :data_competencia, null: false
      t.string :documento_fiscal
      t.string :centro_resultado_sankhya
      t.timestamps
    end
    add_index :expenses, :categoria
    add_index :expenses, :data_competencia

    create_table :team_members do |t|
      t.references :lei_do_bem_record, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :nome, null: false
      t.string :cpf
      t.string :titulacao
      t.string :vinculo
      t.decimal :dedicacao_percentual, precision: 5, scale: 2
      t.decimal :horas_anuais, precision: 8, scale: 2
      t.decimal :custo_anual, precision: 14, scale: 2
      t.boolean :dedicacao_exclusiva, default: false
      t.boolean :contratado_no_ano_base, default: false
      t.timestamps
    end

    create_table :partnerships do |t|
      t.references :lei_do_bem_record, null: false, foreign_key: true
      t.string :ict_nome, null: false
      t.string :ict_cnpj
      t.string :tipo, null: false
      t.text :descricao_parceria
      t.decimal :valor_contrato, precision: 14, scale: 2
      t.date :data_inicio
      t.date :data_fim
      t.timestamps
    end

    create_table :demand_transitions do |t|
      t.references :demand, null: false, foreign_key: true, index: true
      t.string :from_state
      t.string :to_state, null: false
      t.string :event, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.text :justification
      t.datetime :created_at, null: false
    end
    add_index :demand_transitions, %i[demand_id created_at]
  end
end
