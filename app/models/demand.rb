class Demand < ApplicationRecord
  has_paper_trail

  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :transitions, class_name: "DemandTransition", dependent: :restrict_with_exception
  has_one  :lei_do_bem_record, dependent: :destroy
  has_many_attached :attachments

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    image/jpeg
    image/png
  ].freeze
  MAX_ATTACHMENT_SIZE = 10.megabytes

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :trl, inclusion: { in: 1..9 }, allow_nil: true
  validate :attachments_valid
  validate :ods_goals_valid

  scope :busca_titulo, ->(q) { where("title ILIKE ?", "%#{sanitize_sql_like(q)}%") if q.present? }
  scope :por_trl, ->(trl) { where(trl: trl) if trl.present? }
  scope :de, ->(data) { where("created_at >= ?", data.beginning_of_day) if data.present? }
  scope :ate, ->(data) { where("created_at <= ?", data.end_of_day) if data.present? }

  state_machine :aasm_state, initial: :rascunho do
    # 13 estados (PRD)
    state :rascunho
    state :submetida
    state :em_triagem
    state :n1_aprovada
    state :n1_reprovada
    state :n2_em_andamento
    state :n2_completa
    state :awaiting_requester
    state :board_review
    state :elegivel
    state :nao_elegivel
    state :in_execution
    state :concluida
    state :arquivada
    state :cancelada

    event :submeter do
      transition rascunho: :submetida
    end

    event :iniciar_triagem do
      transition submetida: :em_triagem
    end

    event :aprovar_n1 do
      transition em_triagem: :n1_aprovada
    end

    event :reprovar_n1 do
      transition em_triagem: :n1_reprovada
    end

    event :iniciar_n2 do
      transition n1_aprovada: :n2_em_andamento
    end

    event :concluir_n2 do
      transition n2_em_andamento: :n2_completa, if: :n2_completo?
    end

    event :solicitar_revisao do
      transition %i[em_triagem n2_em_andamento n2_completa board_review] => :awaiting_requester
    end

    event :retomar do
      transition awaiting_requester: :submetida
    end

    event :enviar_para_board do
      transition n2_completa: :board_review, if: :parecer_presente?
    end

    event :marcar_elegivel do
      transition %i[n2_completa board_review] => :elegivel, if: :parecer_presente?
    end

    event :marcar_nao_elegivel do
      transition %i[n2_completa board_review] => :nao_elegivel, if: :parecer_presente?
    end

    event :iniciar_execucao do
      transition elegivel: :in_execution
    end

    event :concluir_execucao do
      transition in_execution: :concluida
    end

    event :arquivar do
      transition %i[concluida nao_elegivel] => :arquivada
    end

    event :cancelar do
      transition %i[rascunho submetida em_triagem n1_aprovada n2_em_andamento awaiting_requester board_review] => :cancelada
    end
  end

  N1_FLAGS = %w[
    rotina_operacional
    adequacao_normativa
    solucao_prateleira
    trl_fora_janela
    escopo_nao_tecnologico
  ].freeze

  N2_REQUIRED_FIELDS = %w[motivacao barreira_tecnica metodologia resultado_obtido].freeze

  store_accessor :n2_assessment,
                 :motivacao, :benchmark_anterior, :barreira_tecnica,
                 :metodologia, :stack_tecnologico, :resultado_obtido

  def reprovado_n1?
    n1_flags.any? { |_, v| v == true }
  end

  def n2_completo?
    N2_REQUIRED_FIELDS.all? { |f| send(f).present? }
  end

  def parecer_presente?
    parecer_tecnico.present?
  end

  def to_formpd
    {
      schema_versao: "FORMPD-2025",
      id: id,
      titulo: title,
      solicitante: user.display_name,
      estado: aasm_state,
      trl: trl,
      ods: ods_goals,
      data_criacao: created_at.to_date.iso8601,
      avaliacao_n2: n2_assessment || {}
    }
  end

  private

  def ods_goals_valid
    return if ods_goals.blank?

    invalid = ods_goals.reject { |g| (1..17).cover?(g.to_i) }
    errors.add(:ods_goals, :invalid, message: "deve conter apenas valores entre 1 e 17") if invalid.any?
  end

  def attachments_valid
    attachments.each do |attachment|
      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, :invalid_content_type,
                   message: "#{attachment.filename} tem tipo não permitido")
      end
      if attachment.byte_size > MAX_ATTACHMENT_SIZE
        errors.add(:attachments, :too_large,
                   message: "#{attachment.filename} excede 10MB")
      end
    end
  end
end
