# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2024 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class TalentController < ApplicationController
  before_action :set_talent, only: %i[ show edit update destroy ]

  # GET /talent or /talent.json
  def index
    @talents = Talent.all
  end

  # GET /talent/1 or /talent/1.json
  def show
  end

  # GET /talent/new
  def new
    @talent = Talent.new
  end

  # GET /talent/1/edit
  def edit
  end

  # POST /talent or /talent.json
  def create
    @talent = Talent.new(talent_params)

    respond_to do |format|
      if @talent.save
        format.html { redirect_to talent_url(@talent), notice: "Talent was successfully created." }
        format.json { render :show, status: :created, location: @talent }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @talent.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /talent/1 or /talent/1.json
  def update
    respond_to do |format|
      if @talent.update(talent_params)
        format.html { redirect_to talent_url(@talent), notice: "Talent was successfully updated." }
        format.json { render :show, status: :ok, location: @talent }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @talent.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /talent/1 or /talent/1.json
  def destroy
    @talent.destroy

    respond_to do |format|
      format.html { redirect_to talent_url, notice: "Talent was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_talent
      @talent = Talent.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def talent_params
      params.require(:talent).permit(
        :talent_code, :talent_name, :talent_nbr, 
        :first_name, :last_name, 
        :talent_dob, :talent_release 
      )
    end
end
