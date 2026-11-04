# app/models/concerns/date_range_validatable.rb
module DateRangeValidatable
  extend ActiveSupport::Concern

  class_methods do
    def validates_date_range(start_attr: :start_date, end_attr: :end_date)
      validate do
        s_date = public_send(start_attr)
        e_date = public_send(end_attr)
        return if s_date.blank? || e_date.blank?

        if e_date < s_date
          errors.add(end_attr, "must be on or after #{start_attr.to_s.humanize.downcase}")
        end
      end
    end
  end
end
