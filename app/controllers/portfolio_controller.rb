# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2024 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class PortfolioController < ApplicationController
      before_action :set_portfolio, only: %i[ show edit update destroy ]
 
# ----------------------------------------------------------
# index -- show all portfolios; allow user to select one
# ----------------------------------------------------------

  # GET /portfolio or /portfolio.json
  def index
    @portfolios = Portfolio.all
  end

  # POST /portfolio or /portfolio.json
  def create
    @portfolio = Portfolio.new(portfolio_params)

    respond_to do |format|
      if @portfolio.save
        format.html { redirect_to portfolio_url(@portfolio), notice: "Portfolio was successfully created." }
        format.json { render :show, status: :created, location: @portfolio }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @portfolio.errors, status: :unprocessable_entity }
      end
    end

  end

      # GET /portfolio/new
  def new
     @portfolio = Portfolio.new
  end
 
  # GET /portfolio/1 or /portfolio/1.json
  def show
  end

  # PATCH/PUT /portfolio/1 or /portfolio/1.json
  def update
    respond_to do |format|
      if @portfolio.update(portfolio_params)
        format.html { redirect_to portfolio_url(@portfolio), notice: "Portfolio was successfully updated." }
        format.json { render :show, status: :ok, location: @portfolio }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @portfolio.errors, status: :unprocessable_entity }
      end
    end

  end
  
  # GET /portfolio/1/edit
  def edit
  end
  
  # DELETE /portfolio/1 or /portfolio/1.json
  def destroy
    @portfolio.destroy

    respond_to do |format|
      format.html { redirect_to portfolio_url, notice: "Portfolio was successfully destroyed." }
      format.json { head :no_content }
    end

  end
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  private

  def set_portfolio()
    @portfolio = Portfolio.find(params[:id])
    true     # returning true continues controller action
    
  rescue ActiveRecord::RecordNotFound
    puts "SHOW: ERROR NOT FOUND"
      flash[:notice] = "portfolio doesn't exist"
      flash[:show_flash] = true
      # redirect_back
      false
  end

  # Only allow a list of trusted parameters through.
  def portfolio_params
    params.require(:portfolio).permit(
      :portfolio_title, :portfolio_name
    )
  end

# ------------------------------------------------------------------------------


end
