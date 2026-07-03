# frozen_string_literal: true

class CreateFigroupTables < ActiveRecord::Migration[8.1]
  def change
    create_table :figroup_credentials do |t|
      t.text     :token
      t.datetime :expires_at
      t.string   :company_id
      t.string   :base_url, default: 'https://app.leidobem.com/api/services'
      t.jsonb    :service_ids
      t.references :captured_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :figroup_projects do |t|
      t.string   :fi_project_id
      t.string   :service_id
      t.integer  :fiscal_year
      t.string   :code_project
      t.string   :name
      t.integer  :eligibility
      t.text     :position_fi
      t.text     :explanation_fi
      t.text     :client_response
      t.jsonb    :raw, default: {}
      t.references :demand, null: true, foreign_key: true
      t.datetime :last_pulled_at
      t.datetime :last_pushed_at

      t.timestamps
    end

    add_index :figroup_projects, :fi_project_id, unique: true
  end
end
