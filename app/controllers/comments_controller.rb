class CommentsController < ApplicationController
  before_action :set_demand

  def create
    @comment = @demand.comments.build(comment_params.merge(user: current_user))

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @demand, notice: t("comments.created") }
      end
    else
      respond_to do |format|
        format.html { redirect_to @demand, alert: t("comments.invalid") }
      end
    end
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
