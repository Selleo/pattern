require 'active_record'
require 'ruby2_keywords'

module Patterns
  class Query
    RelationRequired = Class.new(StandardError)

    def initialize(*args)
      @options = args.extract_options!
      @relation = args.first || base_relation

      if relation.nil?
        raise(
          RelationRequired,
          'Queries require a base relation defined. Use .queries method to define relation.'
        )
      elsif !relation.is_a?(ActiveRecord::Relation)
        raise(
          RelationRequired,
          'Queries accept only ActiveRecord::Relation as input'
        )
      end
    end

    class << self
      ruby2_keywords def call(*args)
        new(*args).call
      end
    end

    def call
      query.tap do |relation|
        unless relation.is_a?(ActiveRecord::Relation)
          raise(
            RelationRequired,
            '#query method should return object of ActiveRecord::Relation class'
          )
        end
      end
    end

    def self.queries(subject)
      self.base_relation = subject
    end

    def base_relation
      return nil if self.class.base_relation.nil?

      if self.class.base_relation.is_a?(ActiveRecord::Relation)
        self.class.base_relation
      elsif self.class.base_relation < ActiveRecord::Base
        self.class.base_relation.all
      end
    end

    private

    class << self
      attr_accessor :base_relation
    end

    attr_reader :relation, :options

    def query
      raise(
        NotImplementedError,
        'You need to implement #query method which returns ActiveRecord::Relation object'
      )
    end
  end
end
