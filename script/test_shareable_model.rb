# script/test_shareable_model.rb
# Run via: bin/rails runner script/test_shareable_model.rb

require "securerandom"

puts "=== Testing Shareable Model Concern (Portfolio & Exhibition) ==="

def verify_shareable_behavior(model_class, attrs_a, attrs_b)
  label = model_class.name
  rec_a = model_class.create!(attrs_a)
  rec_b = model_class.create!(attrs_b)

  # 1. Default private state
  raise "#{label}: expected share_token nil on create" unless rec_a.share_token.nil?
  raise "#{label}: expected publicly_shared? false on create" if rec_a.publicly_shared?
  raise "#{label}: expected share_copy_target nil on create" unless rec_a.share_copy_target.nil?
  raise "#{label}: expected private record excluded from publicly_shared scope" if model_class.publicly_shared.exists?(rec_a.id)

  # 2. make_public! assigns 22-char token and persists
  token = rec_a.make_public!
  rec_a.reload
  raise "#{label}: expected 22-char share_token, got #{token.inspect}" unless token.is_a?(String) && token.length == 22
  raise "#{label}: expected persisted share_token to match returned token" unless rec_a.share_token == token
  raise "#{label}: expected publicly_shared? true after make_public!" unless rec_a.publicly_shared?
  raise "#{label}: expected share_copy_target to equal share_token" unless rec_a.share_copy_target == token
  raise "#{label}: expected public record in publicly_shared scope" unless model_class.publicly_shared.exists?(rec_a.id)
  raise "#{label}: expected sibling private record excluded from scope" if model_class.publicly_shared.exists?(rec_b.id)

  # 3. Idempotent make_public! preserves existing token
  second_token = rec_a.make_public!
  raise "#{label}: expected make_public! to be idempotent" unless second_token == token

  # 4. Guarded constraint: uniqueness validation on share_token
  rec_b.share_token = token
  raise "#{label}: expected duplicate share_token to fail validation" if rec_b.valid?
  rec_b.reload

  # 5. make_private! clears token and persists
  rec_a.make_private!
  rec_a.reload
  raise "#{label}: expected share_token nil after make_private!" unless rec_a.share_token.nil?
  raise "#{label}: expected publicly_shared? false after make_private!" if rec_a.publicly_shared?
  raise "#{label}: expected record excluded from scope after make_private!" if model_class.publicly_shared.exists?(rec_a.id)

  # 6. Idempotent make_private!
  raise "#{label}: expected repeated make_private! to return nil" unless rec_a.make_private!.nil?

  puts "  [PASS] #{label} Shareable contract verified."
end

rand_suffix = SecureRandom.hex(4)
created_records = []

begin
  ActiveRecord::Base.transaction do
    verify_shareable_behavior(
      Portfolio,
      { name: "share_p1_#{rand_suffix}", title: "Share Test Portfolio 1" },
      { name: "share_p2_#{rand_suffix}", title: "Share Test Portfolio 2" }
    )

    verify_shareable_behavior(
      Exhibition,
      { title: "Share Test Exhibition 1 #{rand_suffix}" },
      { title: "Share Test Exhibition 2 #{rand_suffix}" }
    )

    raise ActiveRecord::Rollback
  end
ensure
  created_records.each { |rec| rec.destroy if rec.persisted? }
end

puts "=== All Shareable Model Tests Passed ==="
