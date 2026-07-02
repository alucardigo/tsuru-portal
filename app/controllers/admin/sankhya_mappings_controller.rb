# frozen_string_literal: true

module Admin
  class SankhyaMappingsController < BaseController
    def index
      @mappings = SankhyaMapping.order(:kind)
      @healthy = Sankhya::Client.new.healthy?
    rescue StandardError
      @healthy = false
    end

    def create
      mapping = SankhyaMapping.new(mapping_params)
      if mapping.save
        redirect_to admin_sankhya_mappings_path, notice: "Mapeamento \"#{SankhyaMapping::KIND_LABELS[mapping.kind]}\" criado."
      else
        redirect_to admin_sankhya_mappings_path, alert: mapping.errors.full_messages.join(", ")
      end
    end

    def update
      mapping = SankhyaMapping.find(params[:id])
      mapping.update(enabled: params[:enabled] == "true") if params[:enabled].present?
      mapping.update(mapping_params) if params[:sankhya_mapping].present?
      redirect_to admin_sankhya_mappings_path, notice: "Mapeamento atualizado."
    end

    def destroy
      SankhyaMapping.find(params[:id]).destroy
      redirect_to admin_sankhya_mappings_path, notice: "Mapeamento removido."
    end

    def sync
      mapping = SankhyaMapping.find(params[:id])
      unless mapping.enabled
        redirect_to admin_sankhya_mappings_path, alert: "Habilite o mapeamento antes de sincronizar." and return
      end
      result = Sankhya::SyncMapping.call(mapping)
      if result.success?
        redirect_to admin_sankhya_mappings_path, notice: "#{result.count} registro(s) sincronizado(s) para \"#{SankhyaMapping::KIND_LABELS[mapping.kind]}\"."
      else
        redirect_to admin_sankhya_mappings_path, alert: "Falha na sincronização: #{result.error}"
      end
    end

    private

    def mapping_params
      params.require(:sankhya_mapping).permit(:kind, :entidade_sankhya, :campo_codigo, :campo_nome, :campos_extra, :criterio, :enabled)
    end
  end
end
