require 'digest'

module Patterns
  class Calculation
    class_attribute :cache_expiry_every

    def initialize(*args)
      @options = args.extract_options!
      @subject = args.first
    end

    def self.result(*args, &block)
      new(*args).cached_result(&block)
    end

    class << self
      alias_method :result_for, :result
      alias_method :calculate, :result
    end

    def self.set_cache_expiry_every(period)
      self.cache_expiry_every = period
    end

    def cached_result(&block)
      if cache_expiry_period.blank?
        result(&block)
      else
        Rails.cache.fetch(cache_key, expires_in: cache_expiry_period) do
          result(&block)
        end
      end
    end

    private

    attr_reader :subject, :options

    def result
      raise NotImplementedError
    end

    def cache_key
      "#{self.class.name}_#{hash_of(subject, options)}"
    end

    def self.hash_of(*args)
      Digest::SHA1.hexdigest(args.map(&:to_s).join(':'))
    end

    def hash_of(*args)
      self.class.hash_of(*args)
    end

    def cache_expiry_period
      self.class.cache_expiry_every
    end
  end
end
