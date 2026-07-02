class CreateAreas < ActiveRecord::Migration[8.1]
  class MigArea < ActiveRecord::Base
    self.table_name = "areas"
  end

  def up
    create_table :areas do |t|
      t.string :name, null: false, limit: 80
      t.timestamps
    end
    add_index :areas, :name, unique: true

    # Seed: constante legada + valores já usados em users/demands
    names = []
    names |= (Demand::AREAS rescue [])
    names |= select_values("SELECT DISTINCT area FROM users WHERE area IS NOT NULL AND area <> ''")
    names |= select_values("SELECT DISTINCT area_impactada FROM demands WHERE area_impactada IS NOT NULL AND area_impactada <> ''")
    MigArea.reset_column_information
    names.map(&:to_s).reject { |n| n.blank? || n == "Outra" }.uniq.each do |n|
      MigArea.create!(name: n)
    end
  end

  def down
    drop_table :areas
  end

  private

  def select_values(sql)
    ActiveRecord::Base.connection.select_values(sql)
  end
end
