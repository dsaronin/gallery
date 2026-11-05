# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class DashboardController < ApplicationController
  include CatalogHelper

  def index
    @metrics = {
      catalogs:    Catalog.dashboard_metrics,
      portfolios:  Portfolio.dashboard_metrics,
      exhibitions: Exhibition.dashboard_metrics,
      showings:    Showing.dashboard_metrics,
      admin:       Venue.dashboard_metrics
    }
  end

end   # class
