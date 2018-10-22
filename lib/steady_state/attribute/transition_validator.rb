module SteadyState
  module Attribute
    class TransitionValidator < ActiveModel::EachValidator
      def validate_each(obj, attr_name, _value)
        obj.errors.add(attr_name, :invalid) if obj.instance_variable_defined?("@last_valid_#{attr_name}")
      end
    end
  end
end
