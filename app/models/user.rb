class User < ApplicationRecord
  has_paper_trail
  has_many :demands, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :notifications_received, class_name: "Notification", foreign_key: :recipient_id, dependent: :destroy

  # Vínculo hierárquico: colaborador -> supervisor (gestor)
  belongs_to :supervisor, class_name: "User", optional: true
  has_many :subordinados, class_name: "User", foreign_key: :supervisor_id, dependent: :nullify

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable,
         :two_factor_authenticatable,
         otp_secret_encryption_key: Rails.application.credentials.fetch(:otp_secret_key, ENV.fetch("OTP_SECRET_KEY", "a" * 32))

  # fi (5): consultoria FI Group — login próprio para parecer de elegibilidade
  enum :role, { colaborador: 0, gestor: 1, analista_pdi: 2, admin: 3, board: 4, fi: 5 }, default: :colaborador

  validates :name, presence: true, length: { maximum: 100 }

  scope :ativos,    -> { where(active: true) }
  scope :inativos,  -> { where(active: false) }
  scope :supervisores, -> { where(role: %i[gestor admin]) }

  def gestor_or_above?
    gestor? || analista_pdi? || admin? || board?
  end

  def ativo?
    active
  end

  def display_name
    name.presence || email.split("@").first
  end

  def initials
    if name.present?
      name.split.map { |w| w[0].upcase }.first(2).join
    else
      email[0].upcase
    end
  end
end
