class Demand < ApplicationRecord
  has_paper_trail

  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true

  state_machine :aasm_state, initial: :rascunho do
    state :rascunho
    state :submetida
    state :em_triagem
    state :n1_aprovada
    state :n1_reprovada
    state :n2_em_andamento
    state :n2_completa
    state :elegivel
    state :nao_elegivel
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
      transition n2_em_andamento: :n2_completa
    end

    event :marcar_elegivel do
      transition n2_completa: :elegivel
    end

    event :marcar_nao_elegivel do
      transition n2_completa: :nao_elegivel
    end

    event :cancelar do
      transition %i[rascunho submetida em_triagem n1_aprovada n2_em_andamento] => :cancelada
    end
  end

  N1_FLAGS = %w[
    rotina_operacional
    adequacao_normativa
    solucao_prateleira
    trl_fora_janela
    escopo_nao_tecnologico
  ].freeze

  def reprovado_n1?
    n1_flags.any? { |_, v| v == true }
  end
end
