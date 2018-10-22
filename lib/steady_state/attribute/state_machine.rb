module SteadyState
  module Attribute
    class StateMachine
      attr_accessor :start

      def state(state, default: false, from: [])
        states << state
        self.start = state if default
        [from].flatten(1).each do |from_state|
          transitions[from_state] << state
        end
      end

      def new_state(value, last_valid_value)
        State.new(self, value, last_valid_value) unless value.nil?
      end

      def states
        @states ||= []
      end

      def predicates
        states.map { |state| :"#{state.parameterize.underscore}?" }
      end

      def transitions
        @transitions ||= Hash.new { |h, k| h[k] = [] }.with_indifferent_access
      end
    end
  end
end
