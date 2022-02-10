require 'steady_state/attribute/state'
require 'steady_state/attribute/state_machine'
require 'steady_state/attribute/transition_validator'

module SteadyState
  module Attribute
    extend ActiveSupport::Concern

    included do
      cattr_reader :state_machines do
        Hash.new { |h, k| h[k] = StateMachine.new }
      end
    end

    class_methods do
      def steady_state(attr_name, predicates: true, states_getter: true, scopes: SteadyState.active_record?(self), &block) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/LineLength
        overrides = Module.new do
          define_method :"validate_#{attr_name}_transition_to" do |next_value|
            if public_send(attr_name).may_become?(next_value)
              remove_instance_variable("@last_valid_#{attr_name}") if instance_variable_defined?("@last_valid_#{attr_name}")
            elsif !instance_variable_defined?("@last_valid_#{attr_name}")
              instance_variable_set("@last_valid_#{attr_name}", public_send(attr_name))
            end
          end

          define_method :"#{attr_name}=" do |value|
            unless instance_variable_defined?("@#{attr_name}_state_initialized")
              instance_variable_set("@#{attr_name}_state_initialized", true)
            end
            public_send(:"validate_#{attr_name}_transition_to", value) if public_send(attr_name).present?
            super(value)
          end

          define_method :"#{attr_name}" do |*args, &blk|
            unless instance_variable_defined?("@#{attr_name}_state_initialized")
              public_send(:"#{attr_name}=", state_machines[attr_name].start) if super(*args, &blk).blank?
              instance_variable_set("@#{attr_name}_state_initialized", true)
            end
            last_valid_value = instance_variable_get("@last_valid_#{attr_name}") if instance_variable_defined?("@last_valid_#{attr_name}")
            state_machines[attr_name].new_state super(*args, &blk), last_valid_value
          end
        end
        prepend overrides

        state_machines[attr_name].instance_eval(&block)

        if states_getter
          cattr_reader(:"#{attr_name.to_s.pluralize}") do
            state_machines[attr_name].states.map do |state|
              State.new(state_machines[attr_name], state, nil)
            end
          end
        end

        delegate(*state_machines[attr_name].predicates, to: attr_name, allow_nil: true) if predicates
        if scopes
          state_machines[attr_name].states.each do |state|
            scope state.to_sym, -> { where(attr_name.to_sym => state) }
          end
        end

        validates :"#{attr_name}", 'steady_state/attribute/transition' => true,
                                   inclusion: { in: state_machines[attr_name].states }
      end
    end
  end
end
