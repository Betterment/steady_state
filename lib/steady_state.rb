# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_model'
require 'steady_state/attribute'

module SteadyState
  extend ActiveSupport::Concern

  def self.active_record?(klass)
    defined?(ActiveRecord::Base) && klass < ActiveRecord::Base
  end

  included do
    include Attribute
  end
end
