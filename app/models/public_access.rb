# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: PublicAccess Model
# File: app/models/public_access.rb
#
# PURPOSE:
# Represents an opaque master access pass granting read-only GALLERY_VIEWER
# access to publicly shared collections according to access_scope.
# -----------------------------------------------------------------------------

class PublicAccess < ApplicationRecord
  enum :access_scope, ::Gallery::Environ::PUBLIC_ACCESS_SCOPES, default: :all_public

  validates :label, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :assign_token, on: :create

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at >= ?", Date.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

# **********************************************
  def self.dashboard_metrics
    active_passes = active
    {
      active_count:           active_passes.count,
      all_public_count:       active_passes.where(access_scope: access_scopes[:all_public]).count,
      portfolios_only_count:  active_passes.where(access_scope: access_scopes[:portfolios_only]).count,
      exhibitions_only_count: active_passes.where(access_scope: access_scopes[:exhibitions_only]).count
    }
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at.present? && expires_at < Date.current
  end

  def active?
    !revoked? && !expired?
  end

  def revoke!
    return revoked_at if revoked?

    update!(revoked_at: Time.current)
    revoked_at
  end

  # Single seam for future GALLERY_VIEWER master URL construction.
  def share_copy_target
    token
  end
# **********************************************

  private

# **********************************************
  def assign_token
    self.token ||= ::Gallery::Environ.generate_token(16)
  end

# **********************************************
end  #  class
