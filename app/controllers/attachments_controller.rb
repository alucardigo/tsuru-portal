class AttachmentsController < ApplicationController
  before_action :set_demand
  before_action :set_attachment

  def destroy
    authorize @demand, :update?
    @attachment.purge
    redirect_to @demand, notice: t("demands.attachment_removed")
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def set_attachment
    @attachment = @demand.attachments.find(params[:id])
  end
end
