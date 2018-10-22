module SteadyState
  module Attribute
    class State < SimpleDelegator
      attr_accessor :state_machine, :last_valid_value

      def initialize(state_machine, current_value, last_valid_value)
        self.state_machine = state_machine
        self.last_valid_value = last_valid_value
        super(current_value&.inquiry)
      end

      def may_become?(new_value)
        next_values.include?(new_value)
      end

      def next_values
        @next_values ||= state_machine.transitions[last_valid_value || self]
      end

      def previous_values
        @previous_values ||= state_machine.transitions.select { |_, v| v.include?(last_valid_value || self) }.keys
      end
    end
  end
end
