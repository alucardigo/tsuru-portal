class CreateLlmProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_providers do |t|
      t.string  :name,     null: false, limit: 80
      t.string  :kind,     null: false, limit: 20   # openai | anthropic | gemini | local
      t.string  :model,    null: false, limit: 120
      t.string  :base_url                            # obrigatório p/ local; opcional nos demais
      t.text    :api_key                             # criptografada via Active Record encryption
      t.boolean :enabled,  null: false, default: true
      t.timestamps
    end
    add_index :llm_providers, :enabled
  end
end
