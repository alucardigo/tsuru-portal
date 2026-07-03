# frozen_string_literal: true

# Configuração singleton do autosync FI Group (liga/desliga, controle de notificação de expiração).
class FiGroupSetting < ApplicationRecord
  self.table_name = "figroup_settings"

  # Registro único; cria na primeira leitura.
  def self.instance
    first_or_create!
  end
end
