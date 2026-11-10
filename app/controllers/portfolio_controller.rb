# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/controllers/portfolio_controller.rb
class PortfolioController < ApplicationController
  before_action :set_portfolio, only: %i[show edit update destroy]

  def index
    @portfolios = Portfolio.order(created_at: :desc)
  end

  def show
    gallery_state.current_portfolio_id = @portfolio.id
    @portfolio_items = @portfolio.portfolio_items.includes(:photo, :placard).order(:position)
  end

  def new
    @portfolio = Portfolio.new(status: :draft)
  end

  def create
    @portfolio = Portfolio.new(portfolio_params)

    if @portfolio.save
      gallery_state.current_portfolio_id = @portfolio.id
      redirect_to portfolio_path(@portfolio), notice: "Portfolio \"#{@portfolio.name}\" created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @portfolio.update(portfolio_params)
      redirect_to portfolio_path(@portfolio), notice: "Portfolio \"#{@portfolio.name}\" updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    portfolio_name = @portfolio.name
    if @portfolio.destroy
      gallery_state.current_portfolio_id = nil if gallery_state.current_portfolio_id == @portfolio.id
      redirect_to portfolio_index_path, notice: "Portfolio \"#{portfolio_name}\" was removed."
    else
      redirect_to portfolio_path(@portfolio), alert: @portfolio.errors.full_messages.to_sentence
    end
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to portfolio_index_path, alert: "Portfolio not found."
  end

  def portfolio_params
    params.require(:portfolio).permit(:name, :title, :status, :placard_id)
  end
end
