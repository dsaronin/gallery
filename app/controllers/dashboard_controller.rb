# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class DashboardController < ApplicationController
  include CatalogHelper

  def index
    @metrics = {
      catalogs:      Catalog.dashboard_metrics,
      portfolios:    Portfolio.dashboard_metrics,
      exhibitions:   Exhibition.dashboard_metrics,
      showings:      Showing.dashboard_metrics,
      venues:        Venue.dashboard_metrics,
      public_access: PublicAccess.dashboard_metrics
    }
  end

  def branding
    @dark_background = (params[:theme] == "dark")
    @hide_watermark  = true
  end

end   # class
