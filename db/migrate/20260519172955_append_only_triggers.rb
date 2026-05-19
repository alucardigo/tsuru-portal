class AppendOnlyTriggers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION prevent_update_delete() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'Tabela % e append-only - UPDATE/DELETE proibido (ADR-011)', TG_TABLE_NAME;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER demand_transitions_append_only
        BEFORE UPDATE OR DELETE ON demand_transitions
        FOR EACH ROW EXECUTE FUNCTION prevent_update_delete();

      CREATE TRIGGER comments_append_only
        BEFORE UPDATE OR DELETE ON comments
        FOR EACH ROW EXECUTE FUNCTION prevent_update_delete();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS comments_append_only ON comments;
      DROP TRIGGER IF EXISTS demand_transitions_append_only ON demand_transitions;
      DROP FUNCTION IF EXISTS prevent_update_delete();
    SQL
  end
end
