class User < ApplicationRecord
  has_paper_trail
  has_many :demands, dependent: :destroy
  has_many :comments, dependent: :destroy

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable,
         :two_factor_authenticatable,
         otp_secret_encryption_key: Rails.application.credentials.fetch(:otp_secret_key, ENV.fetch("OTP_SECRET_KEY", "a" * 32))

  enum :role, { colaborador: 0, gestor: 1, analista_pdi: 2, admin: 3, board: 4 }, default: :colaborador

  validates :name, presence: true, length: { maximum: 100 }

  def gestor_or_above?
    gestor? || analista_pdi? || admin? || board?
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
