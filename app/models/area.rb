# frozen_string_literal: true

# Áreas da empresa — gerenciáveis pelo admin (antes era a constante Demand::AREAS).
class Area < ApplicationRecord
  validates :name, presence: true, uniqueness: true, length: { maximum: 80 }

  # Fonte única para selects de área. Fallback na constante legada se a tabela
  # estiver vazia (ex.: ambiente novo antes do seed).
  def self.names
    order(:name).pluck(:name).presence || Demand::AREAS
  end

  def users
    User.where(area: name)
  end
end
