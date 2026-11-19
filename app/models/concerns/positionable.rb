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
        end   # fi
      end   # before_validation on

      define_method(:prev_item) do
        scope_id = public_send(scope)
        return nil if position.blank? || scope_id.nil?

        self.class
            .where(scope => scope_id)
            .where("position < ?", position)
            .order(position: :desc)
            .first
      end   #  define_method

      define_method(:next_item) do
        scope_id = public_send(scope)
        return nil if position.blank? || scope_id.nil?

        self.class
            .where(scope => scope_id)
            .where("position > ?", position)
            .order(position: :asc)
            .first
      end  #  define_method

      define_method(:move_higher!) do
        swap_position_with!(prev_item)
      end

      define_method(:move_lower!) do
        swap_position_with!(next_item)
      end

      private

      define_method(:swap_position_with!) do |other|
        return false if other.nil? || position.blank? || other.position.blank?

        my_pos    = position
        other_pos = other.position

        self.class.transaction do
          update_columns(position: 0)
          other.update_columns(position: my_pos)
          update_columns(position: other_pos)
        end

        true
      end

    end   # def acts_as_positionable

  end  # class_methods

end  # module
