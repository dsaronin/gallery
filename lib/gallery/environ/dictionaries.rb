# frozen_string_literal: true

# Gallery: 
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# Domain Enumeration Dictionaries for Environ

module Gallery
  class Environ
    VENUE_TYPES = {
      commercial_gallery: 0,
      museum:             1,
      community_center:   2,
      public_space:       3,
      studio:             4,
      pop_up:             5
    }.freeze

    VENUE_STATUSES = {
      mock:     0,
      pending:  1,
      booked:   2,
      showing:  3,
      archived: 4
    }.freeze

    PORTFOLIO_STATUSES = {
      draft:    0,
      active:   1,
      archived: 2
    }.freeze

    EXHIBITION_STATUSES = {
      draft:     0,
      scheduled: 1,
      active:    2,
      completed: 3,
      archived:  4
    }.freeze

    SALES_POLICIES = {
      not_for_sale:     0,
      direct_inquiry:   1,
      venue_commission: 2,
      fixed_price:      3
    }.freeze

    SHOWING_STATUSES = {
      scheduled:   0,
      in_progress: 1,
      completed:   2,
      canceled:    3
    }.freeze
  end
end
