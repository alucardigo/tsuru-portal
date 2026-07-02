# frozen_string_literal: true

module Admin
  class KnowledgeArticlesController < BaseController
    def index
      @articles = KnowledgeArticle.order(updated_at: :desc)
      @article = KnowledgeArticle.new
    end

    def create
      article = KnowledgeArticle.new(article_params)
      article.created_by = current_user
      if article.save
        redirect_to admin_knowledge_articles_path, notice: "Artigo criado."
      else
        redirect_to admin_knowledge_articles_path, alert: article.errors.full_messages.join(", ")
      end
    end

    def update
      article = KnowledgeArticle.find(params[:id])
      article.update(published: params[:published] == "true") if params[:published].present?
      article.update(article_params) if params[:knowledge_article].present?
      redirect_to admin_knowledge_articles_path
    end

    def destroy
      KnowledgeArticle.find(params[:id]).destroy
      redirect_to admin_knowledge_articles_path, notice: "Artigo removido."
    end

    private

    def article_params
      params.require(:knowledge_article).permit(:title, :category, :body, :published)
    end
  end
end
