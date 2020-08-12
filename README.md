# SteadyState

> A minimalist approach to managing object state, perhaps best described as an "enum with guard rails." Designed to work with `ActiveRecord` and `ActiveModel` classes, or anywhere where Rails validations are used.

## Overview

SteadyState takes idea of a [Finite State Machine](https://en.wikipedia.org/wiki/Finite-state_machine) and cuts out everything but the most basic declaration of states and transitions (i.e. a directed graph). It then uses ActiveModel validations to enforce these transition rules, and plays nicely with other `validates`/`validate` declarations on your model.

All of the features one might expect of a Finite State Machine—take, for example, named events, conditional rules, transition hooks, and event callbacks—can then be implemented using existing methods like `valid?`, `errors`, `after_save`, and so on. This approach is effective in contexts that already rely on these methods for control flow (e.g. a Rails controller).

Both `ActiveRecord` and `ActiveModel` classes are supported, as well as any class adhering to the `ActiveModel::Validations` APIs.

## Installation

Add this to your Gemfile:

```
gem 'steady_state'
```

## Getting Started

To enable stateful behavior on an attribute or column, call `steady_state` with the name of the attribute, and define the states as strings, like so:

```ruby
class Material < ApplicationRecord
  include SteadyState

  steady_state :state do
    state 'solid', default: true
    state 'liquid', from: 'solid'
    state 'gas', from: 'liquid'
    state 'plasma', from: 'gas'
  end
end
```

The `:from` option specifies the state transition rules, i.e. which state(s) a given state is allowed to transition from. It may accept either a single state, or a list of states:

```ruby
state 'cancelled', from: %w(step-1 step-2)
```

The `:default` option defines the state that your object will start in if no other state is provided:

```ruby
material = Material.new
material.state # => 'solid'
```

You may always instantiate a new object in any state, regardless of the default:

```ruby
material = Material.new(state: 'liquid')
material.state # => 'liquid'
```

A class may have any number of these `steady_state` declarations, one per stateful attribute.

### Moving Between States

After your object has been instantiated (or loaded from a database via your ORM), the transitional validations and rules begin to take effect. To change the state, simply use the attribute's setter (e.g. `state=`), and then call `valid?` to see if the change will be accepted:

```ruby
material.with_lock do # if this is an ActiveRecord, a lock is necessary to avoid race conditions
  material.state.solid? # => true
  material.state = 'liquid'
  material.state # => 'liquid'
  material.valid? # => true

  # If the change is not valid, a validation error will be added to the object:
  material.state.liquid? # => true
  material.state = 'solid'
  material.state # => 'solid'
  material.valid? # => false
  material.errors[:state] # => ['is invalid']
end
```

#### A Deliberate Design Choice

Notice that even when the rules are violated, the state attribute does not revert to the previous state, nor is an exception raised inside of the setter. This is a deliberate design decision.

Compare this behavior to, say, a numericality validation:

```ruby
validates :amount, numericality: { greater_than: 0 }

model = MyModel.new(amount: -100)
model.amount # => -100
model.valid? # false
model.errors[:amount] # => ['must be greater than 0']
```

In keeping with the general pattern of `ActiveModel::Validations`, we rely on an object's _current state in memory_ to determine whether or not it is valid. For both the `state` and `amount` fields, the attribute is allowed to hold an invalid value, resulting in a validation error on the object.

### Saving Changes to State

Commonly, state transition events are expected to have names, like "melt" and "evaporate," and other such _action verbs_.
SteadyState has no such expectation, and will not define any named events for you.

If you need them, we encourage you to define these transitions using plain ol' Ruby methods, like so:

```ruby
def melt
  with_lock { update(state: 'liquid') }
end

def melt!
  with_lock { update!(state: 'liquid') }
end
```

The use of `with_lock` is *strongly encouraged* in order to prevent race conditions that might result in invalid state transitions.

This is especially important for operations with side-effects, as a transactional lock will both prevent race conditions and guarantee an atomic rollback
if anything raises an exception:

```ruby
def melt
  with_lock do
    if update(state: 'liquid', melted_at: Time.zone.now)
      owner.update!(melt_count: owner.lock!.melt_count + 1)
      Delayed::Job.enqueue MeltNotificationJob.new(self)
      true
    else
      false
    end
  end
end
```

Here is an example Rails controller making use of this new `melt` method:


```ruby
class MaterialsController < ApplicationController
  def melt
    @material = Material.find(params[:id])
    if @material.melt
      redirect_to material_path(@material)
    else
      render :edit
    end
  end
end
```

With the ability to define your states, apply transitional validations, and persist state changes, you should have everything you need to start using SteadyState inside of your application!

## Addional Features & Configuration

### Predicates

Predicate methods (or "Huh methods") are automatically defined for each state:

```ruby
material = Material.new
material.solid? # => true
material.liquid? # => false
```

You can disable these if, for instance, they conflict with other methods:

```ruby
steady_state :status, predicates: false do
  # ...
end
```

Either way, predicate methods are always available on the value itself:

```ruby
material.status.solid? # => true
material.status.liquid? # => false
```

### Custom Validations

Using the supplied predicate methods, you can define your own validations that take effect only when the object enters a specific state:

```ruby
validates :container, absence: true, if: :solid?
validates :container, presence: true, if: :liquid?
```

With such a validation in place, a state change will not be valid unless the related validation rules are resolved at the same time:

```ruby
object.update!(state: 'liquid') # !! ActiveRecord::RecordInvalid
object.update!(state: 'liquid', container: Cup.new) # 🎉
```

With these tools, you can define rich sets of state-aware rules about your object, and then rely simply on built-in methods like `valid?` and `errors` to determine if an operation violates these rules.

### Scopes

On ActiveRecord objects, scopes are automatically defined for each state:

```ruby
Material.solid # => query for 'solid' records
Material.liquid # => query for 'liquid' records
```

These can be disabled as well:

```ruby
steady_state :step, scopes: false do
  # ...
end
```

### Next and Previous States

The `may_become?` method can be used to see if setting the state to a particular value would be allowed (ignoring all other validations):

```ruby
material.state.may_become?('gas') #=> true
material.state.may_become?('solid') #=> false
```

To get a list of all of the valid state transitions, use the `next_values` method:

```ruby
material.state.next_values # => ['gas']
```

As it stands, state history is not preserved, but it is still possible to get a list of all possible previous states using the `previous_values` method:

```ruby
material.state.previous_values # => ['solid']
```

### ActiveModel Support

SteadyState is also available to classes that are not database-backed, as long as they include the `ActiveModel::Model` mixin:

```ruby
class Material
  include ActiveModel::Model

  attr_accessor :state

  steady_state :state do
    state 'solid', default: true
    state 'liquid', from: 'solid'
  end

  def melt
    self.state = 'liquid'
    valid? # will return `false` if state transition is invalid
  end
  
  def melt!
    self.state = 'liquid'
    validate! # will raise an exception if state transition is invalid
  end
end
```

## How to Contribute

We would love for you to contribute! Anything that benefits the majority of `steady_state` users—from a documentation fix to an entirely new feature—is encouraged.

Before diving in, check our issue tracker and consider creating a new issue to get early feedback on your proposed change.

#### Suggested Workflow

* Fork the project and create a new branch for your contribution.
* Write your contribution (and any applicable test coverage).
* Make sure all tests pass (bundle exec rake).
* Submit a pull request.
