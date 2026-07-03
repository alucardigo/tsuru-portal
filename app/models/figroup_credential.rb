# frozen_string_literal: true

# Credencial de acesso à API interna do LeidoBem (FI Group).
# O token JWT (~1h de vida) é capturado do navegador e armazenado criptografado
# (Active Record encryption — mesmas chaves já configuradas em prod).
# Ver contrato: docs/FIGROUP_API_CONTRATO.md
class FiGroupCredential < ApplicationRecord
  self.table_name = "figroup_credentials"

  encrypts :token

  belongs_to :captured_by, class_name: "User", optional: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.current
    order(created_at: :desc).first
  end

  def active?
    expires_at.present? && expires_at > Time.current
  end

  def service_id_for(year)
    service_ids.to_h[year.to_s]
  end
end
