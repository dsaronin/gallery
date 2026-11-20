# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/controllers/public_access_controller.rb
class PublicAccessController < ApplicationController
  before_action :set_public_access, only: %i[edit update revoke]

# ***********************************************
  def index
    @metrics = PublicAccess.dashboard_metrics
    @public_accesses = PublicAccess.order(
      Arel.sql("CASE WHEN revoked_at IS NULL THEN 0 ELSE 1 END"),
      created_at: :desc
    )
  end

  def new
    @public_access = PublicAccess.new(access_scope: :all_public)
  end

  def create
    @public_access = PublicAccess.new(public_access_params)

    if @public_access.save
      redirect_to public_access_index_path, notice: "Public access \"#{@public_access.label}\" created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @public_access.update(public_access_params)
      redirect_to public_access_index_path, notice: "Public access \"#{@public_access.label}\" updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # PATCH /public_access/:id/revoke
  def revoke
    @public_access.revoke!
    redirect_to public_access_index_path, notice: "Public access \"#{@public_access.label}\" has been revoked."
  end
# ***********************************************

  private

# ***********************************************
  def set_public_access
    @public_access = PublicAccess.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_access_index_path, alert: "Public access pass not found."
  end

  def public_access_params
    params.require(:public_access).permit(:label, :access_scope, :expires_at, :notes)
  end

# ***********************************************
end   #   class
