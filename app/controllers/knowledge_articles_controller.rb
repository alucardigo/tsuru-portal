# frozen_string_literal: true

# Bloco F — Biblioteca PD&I (leitura para todos os usuários autenticados).
class KnowledgeArticlesController < ApplicationController
  def index
    @articles = KnowledgeArticle.published.by_category(params[:category]).busca(params[:q]).order(:title)
    @categories = KnowledgeArticle.published.distinct.pluck(:category)
  end

  def show
    @article = KnowledgeArticle.published.find(params[:id])
  end
end
