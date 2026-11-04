# app/models/concerns/positionable.rb
module Positionable
  extend ActiveSupport::Concern

  class_methods do
    def acts_as_positionable(scope:)
      validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
      validates :position, uniqueness: { scope: scope }

      before_validation on: :create do
        if position.blank?
          parent = public_send(scope.to_s.delete_suffix("_id"))
          max_position = parent&.public_send(self.class.table_name)&.maximum(:position) || 0
          self.position = max_position + 1
        end
      end
    end
  end
end
