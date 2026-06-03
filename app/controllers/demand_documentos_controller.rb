# frozen_string_literal: true

# Upload e gestao de documentos internos de um projeto/demand.
# Usa ActiveStorage (service "local" em prod por enquanto).
class DemandDocumentosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand
  before_action :authorize_demand!

  ALLOWED_TYPES = %w[
    application/pdf
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation
    image/jpeg image/png image/webp
    text/plain text/csv
    application/zip
  ].freeze
  MAX_SIZE = 25.megabytes

  def index
    @documentos = @demand.documentos.includes(:blob).order(created_at: :desc)
  end

  def create
    files = Array(params[:documentos])
    if files.blank?
      redirect_back fallback_location: demand_documentos_path(@demand),
                    alert: "Selecione ao menos um arquivo." and return
    end

    rejeitados = []
    aceitos    = []

    files.each do |f|
      next if f.blank?
      if !ALLOWED_TYPES.include?(f.content_type)
        rejeitados << "#{f.original_filename} (tipo nao suportado)"
      elsif f.size > MAX_SIZE
        rejeitados << "#{f.original_filename} (>25MB)"
      else
        @demand.documentos.attach(io: f.tempfile, filename: f.original_filename,
                                  content_type: f.content_type,
                                  metadata: { uploaded_by_id: current_user.id })
        aceitos << f.original_filename
      end
    end

    msg = []
    msg << "#{aceitos.size} arquivo(s) enviado(s)" if aceitos.any?
    msg << "Rejeitados: #{rejeitados.join(', ')}" if rejeitados.any?
    redirect_to demand_documentos_path(@demand), notice: msg.join(" | ").presence || "Nenhum arquivo enviado."
  end

  def destroy
    doc = @demand.documentos.find(params[:id])
    doc.purge_later
    redirect_to demand_documentos_path(@demand), notice: "Documento removido."
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def authorize_demand!
    return if current_user.admin? || current_user.analista_pdi? || current_user.board?
    return if @demand.user_id == current_user.id
    return if current_user.gestor? # gestor vê documentos
    redirect_to demand_path(@demand), alert: "Sem permissão para documentos deste projeto."
  end
end
