# frozen_string_literal: true

require 'open3'

RSpec.describe 'rbi/steady_state.rbi' do
  def srb_tc(fixture)
    gem_root = File.expand_path('..', __dir__)
    Open3.capture2e(
      'bundle', 'exec', 'srb', 'tc',
      'rbi/steady_state.rbi', "spec/support/rbi_typecheck/#{fixture}",
      chdir: gem_root
    )
  end

  it 'typechecks a Sorbet-enabled consumer of the steady_state DSL' do
    output, status = srb_tc('valid_consumer.rb')
    expect(status).to be_success, "expected `srb tc` to pass, got:\n#{output}"
  end

  it 'rejects unknown methods inside the DSL block' do
    output, status = srb_tc('invalid_consumer.rb')
    expect(status).not_to be_success
    expect(output).to include('Method `not_a_dsl_method` does not exist')
    expect(output).to include('SteadyState::Attribute::StateMachine')
  end
end
