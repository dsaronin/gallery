# script/test_public_access_model.rb
# Run via: bin/rails runner script/test_public_access_model.rb

require "securerandom"

puts "=== Testing PublicAccess Model ==="

rand_suffix = SecureRandom.hex(4)

ActiveRecord::Base.transaction do
  baseline_metrics = PublicAccess.dashboard_metrics

  # 1. Default creation & token generation
  pass_all = PublicAccess.create!(label: "Curator A #{rand_suffix}")
  raise "Expected 22-char token, got #{pass_all.token.inspect}" unless pass_all.token.is_a?(String) && pass_all.token.length == 22
  raise "Expected default access_scope to be all_public" unless pass_all.all_public?
  raise "Expected new pass to be active?" unless pass_all.active?
  raise "Expected new pass not revoked?" if pass_all.revoked?
  raise "Expected new pass not expired?" if pass_all.expired?
  raise "Expected share_copy_target to equal token" unless pass_all.share_copy_target == pass_all.token
  puts "1. Default creation, token generation, and share_copy_target passed."

  # 2. Guarded validations: label presence & token uniqueness
  missing_label = PublicAccess.new(label: "")
  raise "Expected blank label to fail validation" if missing_label.valid?

  dup_token = PublicAccess.new(label: "Duplicate #{rand_suffix}", token: pass_all.token)
  raise "Expected duplicate token to fail validation" if dup_token.valid?
  puts "2. Label presence and token uniqueness validations passed."

  # 3. Scopes and expiration boundaries
  pass_port = PublicAccess.create!(
    label: "Portfolio Reviewer #{rand_suffix}",
    access_scope: :portfolios_only,
    expires_at: Date.current
  )
  pass_exh = PublicAccess.create!(
    label: "Exhibition Reviewer #{rand_suffix}",
    access_scope: :exhibitions_only,
    expires_at: Date.current + 7.days
  )
  pass_expired = PublicAccess.create!(
    label: "Expired Guest #{rand_suffix}",
    access_scope: :all_public,
    expires_at: Date.current - 1.day
  )

  raise "Expected expires_at == today to remain active?" unless pass_port.active?
  raise "Expected expires_at in future to be active?" unless pass_exh.active?
  raise "Expected expires_at in past to be expired?" unless pass_expired.expired?
  raise "Expected expired pass to fail active?" if pass_expired.active?
  raise "Expected expired pass excluded from active scope" if PublicAccess.active.exists?(pass_expired.id)
  puts "3. Scope enums and expiration boundaries passed."

  # 4. Dashboard metrics reflect active counts only
  metrics = PublicAccess.dashboard_metrics
  raise "Expected active_count delta +3" unless metrics[:active_count] == baseline_metrics[:active_count] + 3
  raise "Expected all_public_count delta +1" unless metrics[:all_public_count] == baseline_metrics[:all_public_count] + 1
  raise "Expected portfolios_only_count delta +1" unless metrics[:portfolios_only_count] == baseline_metrics[:portfolios_only_count] + 1
  raise "Expected exhibitions_only_count delta +1" unless metrics[:exhibitions_only_count] == baseline_metrics[:exhibitions_only_count] + 1
  puts "4. PublicAccess.dashboard_metrics passed."

  # 5. Soft-revoke lifecycle and idempotency
  revoked_ts = pass_port.revoke!
  pass_port.reload
  raise "Expected revoked? true after revoke!" unless pass_port.revoked?
  raise "Expected active? false after revoke!" if pass_port.active?
  raise "Expected revoked pass excluded from active scope" if PublicAccess.active.exists?(pass_port.id)
  raise "Expected revoked pass included in revoked scope" unless PublicAccess.revoked.exists?(pass_port.id)

  second_ts = pass_port.revoke!
  raise "Expected revoke! to be idempotent" unless second_ts == revoked_ts

  post_revoke_metrics = PublicAccess.dashboard_metrics
  raise "Expected active_count delta +2 after revoke" unless post_revoke_metrics[:active_count] == baseline_metrics[:active_count] + 2
  raise "Expected portfolios_only_count back to baseline" unless post_revoke_metrics[:portfolios_only_count] == baseline_metrics[:portfolios_only_count]
  puts "5. Soft-revoke lifecycle and idempotency passed."

  raise ActiveRecord::Rollback
end

puts "=== All PublicAccess Model Tests Passed ==="
