# typed: true
# frozen_string_literal: true

# The `steady_state` block is bound to StateMachine, so unknown methods
# inside it must fail to typecheck. This file is never loaded at runtime;
# spec/rbi_spec.rb asserts that `srb tc` rejects it, guarding against the
# sig regressing to an unbound block (which would silently make the whole
# block untyped, and `state` calls unchecked).
class InvalidConsumer
  include SteadyState

  steady_state :temperature do
    not_a_dsl_method 'solid'
  end
end
