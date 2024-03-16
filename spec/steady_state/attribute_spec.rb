# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SteadyState::Attribute do
  let(:steady_state_class) do
    Class.new do
      include ActiveModel::Model
      include SteadyState

      def self.model_name
        ActiveModel::Name.new(self, nil, 'steady_state_class')
      end
    end
  end
  subject { steady_state_class.new }

  shared_examples 'a basic state machine' do
    it 'starts on initial state' do
      expect(subject.state).to eq 'solid'
    end

    it 'allows initialization to the initial state' do
      expect(steady_state_class.new(state: 'solid')).to be_valid
    end

    it 'allows initialization to other states' do
      expect(steady_state_class.new(state: 'plasma')).to be_valid
    end

    it 'adds validation errors when initializing to an invalid state' do
      object = steady_state_class.new(state: 'banana')
      expect(object).not_to be_valid
      expect(object.errors[:state]).to contain_exactly('is not included in the list')
    end

    it 'allows valid transitions' do
      expect(subject.state.may_become?('liquid')).to eq true
      expect(subject.state.next_values).to contain_exactly('liquid')
      expect(subject.state.previous_values).to be_empty
      expect { subject.state = 'liquid' }.to change { subject.state }.from('solid').to('liquid')
      expect(subject).to be_valid

      expect(subject.state.may_become?('gas')).to eq true
      expect(subject.state.next_values).to contain_exactly('gas')
      expect(subject.state.previous_values).to contain_exactly('solid')
      expect { subject.state = 'gas' }.to change { subject.state }.from('liquid').to('gas')
      expect(subject).to be_valid

      expect(subject.state.may_become?('plasma')).to eq true
      expect(subject.state.next_values).to contain_exactly('plasma')
      expect(subject.state.previous_values).to contain_exactly('liquid')
      expect { subject.state = 'plasma' }.to change { subject.state }.from('gas').to('plasma')
      expect(subject).to be_valid
      expect(subject.state.next_values).to be_empty
      expect(subject.state.previous_values).to contain_exactly('gas')
    end

    it 'adds validation errors for invalid transitions' do
      expect(subject.state.may_become?('gas')).to eq false
      expect { subject.state = 'gas' }.to change { subject.state }.from('solid').to('gas')
      expect(subject).not_to be_valid
      expect(subject.errors[:state]).to contain_exactly('is invalid')
      expect(subject.state.next_values).to contain_exactly('liquid')
      expect(subject.state.previous_values).to be_empty

      expect(subject.state.may_become?('plasma')).to eq false
      expect { subject.state = 'plasma' }.to change { subject.state }.from('gas').to('plasma')
      expect(subject).not_to be_valid
      expect(subject.errors[:state]).to contain_exactly('is invalid')
      expect(subject.state.next_values).to contain_exactly('liquid')
      expect(subject.state.previous_values).to be_empty

      expect(subject.state.may_become?('solid')).to eq false
      expect { subject.state = 'solid' }.to change { subject.state }.from('plasma').to('solid')
      expect(subject).not_to be_valid
      expect(subject.errors[:state]).to contain_exactly('is invalid')
      expect(subject.state.next_values).to contain_exactly('liquid')
      expect(subject.state.previous_values).to be_empty
    end
  end

  context 'with a single field and nothing fancy' do
    before do
      steady_state_class.module_eval do
        attr_accessor :state

        steady_state :state do
          state 'solid', default: true
          state 'liquid', from: 'solid'
          state 'gas', from: 'liquid'
          state 'plasma', from: 'gas'
        end
      end
    end

    it_behaves_like 'a basic state machine'

    context 'with inheritance' do
      let(:subclass) do
        Class.new(steady_state_class) do
          def initialize # rubocop:disable Lint/MissingSuper
            # I do my own thing.
          end
        end
      end
      subject { subclass.new }

      it_behaves_like 'a basic state machine'
    end

    context 'with an existing state value' do
      before do
        steady_state_class.module_eval do
          def state
            @state ||= 'liquid'
          end
        end
      end

      it 'starts on existing state' do
        expect(subject.state).to eq 'liquid'
      end

      it 'does not allow initialization to an invalid next state' do
        object = steady_state_class.new(state: 'solid')
        expect(object).not_to be_valid
        expect(object.errors[:state]).to contain_exactly('is invalid')
      end

      it 'allows initialization to a valid next state' do
        expect(steady_state_class.new(state: 'gas')).to be_valid
      end

      it 'adds validation errors when initializing to an invalid state' do
        object = steady_state_class.new(state: 'banana')
        expect(object).not_to be_valid
        expect(object.errors[:state]).to contain_exactly('is invalid', 'is not included in the list')
      end

      it 'allows valid transitions' do
        expect(subject).to be_valid
        expect(subject.state.may_become?('gas')).to eq true
        expect(subject.state.next_values).to contain_exactly('gas')
        expect(subject.state.previous_values).to contain_exactly('solid')
        expect { subject.state = 'gas' }.to change { subject.state }.from('liquid').to('gas')
        expect(subject).to be_valid

        expect(subject.state.may_become?('plasma')).to eq true
        expect(subject.state.next_values).to contain_exactly('plasma')
        expect(subject.state.previous_values).to contain_exactly('liquid')
        expect { subject.state = 'plasma' }.to change { subject.state }.from('gas').to('plasma')
        expect(subject).to be_valid
        expect(subject.state.next_values).to be_empty
        expect(subject.state.previous_values).to contain_exactly('gas')
      end

      it 'adds validation errors for invalid transitions' do
        expect(subject.state.may_become?('plasma')).to eq false
        expect { subject.state = 'plasma' }.to change { subject.state }.from('liquid').to('plasma')
        expect(subject).not_to be_valid
        expect(subject.errors[:state]).to contain_exactly('is invalid')
        expect(subject.state.next_values).to contain_exactly('gas')
        expect(subject.state.previous_values).to contain_exactly('solid')

        expect(subject.state.may_become?('solid')).to eq false
        expect { subject.state = 'solid' }.to change { subject.state }.from('plasma').to('solid')
        expect(subject).not_to be_valid
        expect(subject.errors[:state]).to contain_exactly('is invalid')
        expect(subject.state.next_values).to contain_exactly('gas')
        expect(subject.state.previous_values).to contain_exactly('solid')
      end
    end
  end

  context 'with a field reachable by multiple states' do
    before do
      steady_state_class.module_eval do
        attr_accessor :step

        steady_state :step do
          state 'step-1', default: true
          state 'step-2', from: 'step-1'
          state 'cancelled', from: %w(step-1 step-2)
        end
      end
    end

    it 'allows transition from first state' do
      expect(subject.step.may_become?('step-1')).to eq false
      expect(subject.step.may_become?('step-2')).to eq true
      expect(subject.step.may_become?('cancelled')).to eq true
      expect(subject.step.next_values).to match_array(%w(cancelled step-2))
      expect(subject.step.previous_values).to be_empty
      expect { subject.step = 'cancelled' }.to change { subject.step }.from('step-1').to('cancelled')
      expect(subject.step.next_values).to be_empty
      expect(subject.step.previous_values).to match_array(%w(step-1 step-2))
      expect(subject).to be_valid
    end

    it 'allows transition from second state' do
      expect(subject.step.may_become?('step-1')).to eq false
      expect(subject.step.may_become?('step-2')).to eq true
      expect(subject.step.may_become?('cancelled')).to eq true
      expect(subject.step.next_values).to match_array(%w(cancelled step-2))
      expect(subject.step.previous_values).to be_empty
      expect { subject.step = 'step-2' }.to change { subject.step }.from('step-1').to('step-2')
      expect(subject).to be_valid

      expect(subject.step.may_become?('step-1')).to eq false
      expect(subject.step.may_become?('step-2')).to eq false
      expect(subject.step.may_become?('cancelled')).to eq true
      expect(subject.step.next_values).to contain_exactly('cancelled')
      expect(subject.step.previous_values).to contain_exactly('step-1')
      expect { subject.step = 'cancelled' }.to change { subject.step }.from('step-2').to('cancelled')
      expect(subject.step.next_values).to be_empty
      expect(subject.step.previous_values).to match_array(%w(step-1 step-2))
      expect(subject).to be_valid
    end
  end

  context 'with the predicates option' do
    before do
      options = opts
      steady_state_class.module_eval do
        attr_accessor :door

        steady_state :door, **options do
          state 'open', default: true
          state 'closed', from: 'open'
          state 'locked', from: 'closed'
        end
      end
    end

    context 'default' do
      let(:opts) { {} }

      it 'defines a predicate method for each state' do
        expect(subject).to respond_to(:open?)
        expect(subject).to respond_to(:closed?)
        expect(subject).to respond_to(:locked?)

        expect(subject.open?).to eq true
        expect(subject.closed?).to eq false
        expect(subject.locked?).to eq false

        subject.door = 'closed'
        expect(subject.open?).to eq false
        expect(subject.closed?).to eq true
        expect(subject.locked?).to eq false

        subject.door = 'locked'
        expect(subject.open?).to eq false
        expect(subject.closed?).to eq false
        expect(subject.locked?).to eq true
      end
    end

    context 'enabled' do
      let(:opts) { { predicates: true } }

      it 'defines a predicate method for each state' do
        expect(subject).to respond_to(:open?)
        expect(subject).to respond_to(:closed?)
        expect(subject).to respond_to(:locked?)

        expect(subject.open?).to eq true
        expect(subject.closed?).to eq false
        expect(subject.locked?).to eq false

        subject.door = 'closed'
        expect(subject.open?).to eq false
        expect(subject.closed?).to eq true
        expect(subject.locked?).to eq false

        subject.door = 'locked'
        expect(subject.open?).to eq false
        expect(subject.closed?).to eq false
        expect(subject.locked?).to eq true
      end
    end

    context 'disabled' do
      let(:opts) { { predicates: false } }

      it 'does not define predicate methods' do
        expect(subject).not_to respond_to(:open?)
        expect(subject).not_to respond_to(:closed?)
        expect(subject).not_to respond_to(:locked?)
      end
    end
  end

  context 'with the states_getter option' do
    let(:query_object) { double(where: []) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      options = opts
      steady_state_class.module_eval do
        attr_accessor :car

        steady_state :car, **options do
          state 'driving', default: true
          state 'stopped', from: 'driving'
          state 'parked', from: 'stopped'
        end
      end
    end

    context 'default' do
      let(:opts) { {} }

      it 'defines states getter method' do
        expect(steady_state_class.cars).to eq %w(driving stopped parked)
      end
    end

    context 'disabled' do
      let(:opts) { { states_getter: false } }

      it 'does not define states getter method' do
        expect { steady_state_class.cars }.to raise_error(NoMethodError, /undefined method `cars'/)
      end
    end
  end

  context 'with the scopes option' do
    let(:query_object) { double(where: []) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      options = opts
      steady_state_class.module_eval do
        attr_accessor :car

        def self.defined_scopes
          @defined_scopes ||= {}
        end

        def self.scope(name, callable)
          defined_scopes[name] ||= callable
        end

        steady_state :car, **options do
          state 'driving', default: true
          state 'stopped', from: 'driving'
          state 'parked', from: 'stopped'
        end
      end
    end

    context 'default' do
      let(:opts) { {} }

      it 'does not define scope methods' do
        expect(steady_state_class.defined_scopes.keys).to eq []
      end

      context 'on an ActiveRecord' do
        let(:steady_state_class) do
          stub_const('ActiveRecord::Base', Class.new)

          Class.new(ActiveRecord::Base) do
            include ActiveModel::Model
            include SteadyState
          end
        end

        it 'defines a scope for each state' do
          expect(steady_state_class.defined_scopes.keys).to eq %i(driving stopped parked)

          expect(query_object).to receive(:where).with(car: 'driving')
          query_object.instance_exec(&steady_state_class.defined_scopes[:driving])
          expect(query_object).to receive(:where).with(car: 'stopped')
          query_object.instance_exec(&steady_state_class.defined_scopes[:stopped])
          expect(query_object).to receive(:where).with(car: 'parked')
          query_object.instance_exec(&steady_state_class.defined_scopes[:parked])
        end
      end
    end

    context 'enabled' do
      let(:opts) { { scopes: true } }

      it 'defines a scope for each state' do
        expect(steady_state_class.defined_scopes.keys).to eq %i(driving stopped parked)

        expect(query_object).to receive(:where).with(car: 'driving')
        query_object.instance_exec(&steady_state_class.defined_scopes[:driving])
        expect(query_object).to receive(:where).with(car: 'stopped')
        query_object.instance_exec(&steady_state_class.defined_scopes[:stopped])
        expect(query_object).to receive(:where).with(car: 'parked')
        query_object.instance_exec(&steady_state_class.defined_scopes[:parked])
      end
    end

    context 'enabled with prefix: true' do
      let(:opts) { { scopes: { prefix: true } } }

      it 'defines a scope for each state, prefixed with the name of the state machine' do
        expect(steady_state_class.defined_scopes.keys).to eq %i(car_driving car_stopped car_parked)

        expect(query_object).to receive(:where).with(car: 'driving')
        query_object.instance_exec(&steady_state_class.defined_scopes[:car_driving])
        expect(query_object).to receive(:where).with(car: 'stopped')
        query_object.instance_exec(&steady_state_class.defined_scopes[:car_stopped])
        expect(query_object).to receive(:where).with(car: 'parked')
        query_object.instance_exec(&steady_state_class.defined_scopes[:car_parked])
      end
    end

    context 'enabled with a custom prefix such as prefix: :automobile' do
      let(:opts) { { scopes: { prefix: :automobile } } }

      it 'defines a scope for each state with the custom prefix' do
        expect(steady_state_class.defined_scopes.keys).to eq %i(automobile_driving automobile_stopped automobile_parked)

        expect(query_object).to receive(:where).with(car: 'driving')
        query_object.instance_exec(&steady_state_class.defined_scopes[:automobile_driving])
        expect(query_object).to receive(:where).with(car: 'stopped')
        query_object.instance_exec(&steady_state_class.defined_scopes[:automobile_stopped])
        expect(query_object).to receive(:where).with(car: 'parked')
        query_object.instance_exec(&steady_state_class.defined_scopes[:automobile_parked])
      end
    end

    context 'disabled' do
      let(:opts) { { scopes: false } }

      it 'does not define scope methods' do
        expect(steady_state_class.defined_scopes.keys).to eq []
      end
    end
  end
end
