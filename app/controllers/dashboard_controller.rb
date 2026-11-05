# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class DashboardController < ApplicationController
  def index
    # Stubbed telemetry metrics for prototype wireframing
    @metrics = {
      catalogs: {
        ingested_count: 3,
        available_disk_count: 8,
        indexed_photos_count: 142
      },
      portfolios: {
        total_count: 4,
        active_count: 2,
        draft_count: 2,
        curated_photos_count: 38
      },
      exhibitions: {
        staged_count: 2,
        planning_count: 1,
        active_count: 1
      },
      showings: {
        booked_count: 3,
        next_date: "11/20/2026",
        next_venue: "Oakland Center Gallery",
        days_remaining: 16
      },
      admin: {
        venues_count: 2,
        total_wall_meters: 45.5,
        talents_count: 5,
        categories_count: 6,
        tags_count: 24
      }
    }
  end
end
