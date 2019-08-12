module Patterns
  class Calculation
    class_attribute :cache_expiry_every

    def initialize(*args)
      @options = args.extract_options!
      @subject = args.first
    end

    def self.result(*args)
      new(*args).cached_result
    end

    class << self
      alias_method :result_for, :result
      alias_method :calculate, :result
    end

    def self.set_cache_expiry_every(period)
      self.cache_expiry_every = period
    end

    def cached_result
      if cache_expiry_period.blank?
        result
      else
        Rails.cache.fetch(cache_key, expires_in: cache_expiry_period) do
          result
        end
      end
    end

    private

    attr_reader :subject, :options

    def result
      raise NotImplementedError
    end

    def cache_key
      "#{self.class.name}_#{[subject, options].hash}"
    end

    def cache_expiry_period
      self.class.cache_expiry_every
    end
  end
end
