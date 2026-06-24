# frozen_string_literal: true

module Admin
  class TagsController < ApplicationController
    before_action :authenticate_user!
    before_action :admin_only

    def index
      @tags = Tag.order(:name)
      @tag  = Tag.new(color: "gray")
    end

    def create
      @tag = Tag.new(tag_params)
      if @tag.save
        redirect_to admin_tags_path, notice: "Tag criada."
      else
        redirect_to admin_tags_path, alert: @tag.errors.full_messages.join(", ")
      end
    end

    def update
      tag = Tag.find(params[:id])
      tag.update(tag_params)
      redirect_to admin_tags_path
    end

    def destroy
      Tag.find(params[:id]).destroy
      redirect_to admin_tags_path, notice: "Tag removida."
    end

    private

    def tag_params
      params.require(:tag).permit(:name, :color)
    end

    def admin_only
      redirect_to root_path, alert: "Acesso restrito." unless current_user&.admin?
    end
  end
end
