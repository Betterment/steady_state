# typed: true
# frozen_string_literal: true

# Mirrors how a Sorbet-enabled consumer uses the DSL. This file is never
# loaded at runtime; it exists only to be typechecked by `srb tc` in
# spec/rbi_spec.rb, alongside rbi/steady_state.rbi.
class ValidConsumer
  include SteadyState

  steady_state :temperature do
    state 'solid', default: true
    state 'liquid', from: 'solid'
    state 'gas', from: %w(liquid)
    state 'plasma', from: %w(liquid gas)
  end

  steady_state :career, predicates: false, states_getter: false, scopes: { prefix: true } do
    state 'intern', default: true
    state 'developer', from: 'intern'
  end
end
