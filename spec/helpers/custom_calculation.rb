require 'active_support/all'
require 'active_support/testing/time_helpers'
require_relative 'rails_redis_cache_mock'
require_relative '../../lib/patterns/calculation'

CustomCalculation = Class.new(Patterns::Calculation) do
  set_cache_expiry_every 1.hour
  class_attribute :counter
  self.counter = 0

  private

  def result
    self.class.counter += 1
  end
end
