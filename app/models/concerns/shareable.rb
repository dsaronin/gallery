# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: Shareable Concern
# File: app/models/concerns/shareable.rb
#
# PURPOSE:
# Manages public/private visibility via opaque share_token assignment for
# Portfolio and Exhibition collections.
# -----------------------------------------------------------------------------

module Shareable
  extend ActiveSupport::Concern

  included do
    validates :share_token, uniqueness: true, allow_nil: true

    scope :publicly_shared, -> { where.not(share_token: nil) }
  end

  def publicly_shared?
    share_token.present?
  end

  def make_public!
    return share_token if publicly_shared?

    update!(share_token: ::Gallery::Environ.generate_token(16))
    share_token
  end

  def make_private!
    return nil unless publicly_shared?

    update!(share_token: nil)
    nil
  end

  # Single seam for future GALLERY_VIEWER URL construction.
  def share_copy_target
    share_token
  end

end   # module
