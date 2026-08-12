# typed: true

# Sorbet annotations for SteadyState's DSL, shipped with the gem so that
# Tapioca merges them into consumers' generated gem RBIs.
#
# The key annotation is the `T.proc.bind` on `steady_state`'s block: the
# block is `instance_eval`'d against a `StateMachine`, so without the bind,
# Sorbet resolves `state` calls against the including class and errors.

module SteadyState
  mixes_in_class_methods SteadyState::Attribute::ClassMethods
end

module SteadyState::Attribute
  mixes_in_class_methods SteadyState::Attribute::ClassMethods
end

module SteadyState::Attribute::ClassMethods
  sig do
    params(
      attr_name: T.any(Symbol, String),
      predicates: T::Boolean,
      states_getter: T::Boolean,
      scopes: T.any(T::Boolean, T::Hash[Symbol, T.untyped]),
      block: T.proc.bind(SteadyState::Attribute::StateMachine).void,
    ).void
  end
  def steady_state(attr_name, predicates: true, states_getter: true, scopes: false, &block); end
end

class SteadyState::Attribute::StateMachine
  sig do
    params(
      state: String,
      default: T::Boolean,
      from: T.any(String, T::Array[String]),
    ).void
  end
  def state(state, default: false, from: []); end

  sig { returns(T.nilable(String)) }
  def start; end

  sig { returns(T::Array[String]) }
  def states; end

  sig { returns(T::Array[Symbol]) }
  def predicates; end
end
