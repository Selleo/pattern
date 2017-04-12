require "active_record"

module Patterns
  class Query
    RelationRequired = Class.new(StandardError)

    def initialize(*args)
      @options = args.extract_options!
      @relation = args.first || self.class.base_relation

      if relation.nil?
        raise(
            RelationRequired,
            "Queries require a base relation defined. Use .queries method to define relation."
        )
      elsif !relation.is_a?(ActiveRecord::Relation)
        raise(
            RelationRequired,
            "Queries accept only ActiveRecord::Relation as input"
        )
      end
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      query.tap do |relation|
        unless relation.is_a?(ActiveRecord::Relation)
          raise(
              RelationRequired,
              "#query method should return object of ActiveRecord::Relation class"
          )
        end
      end
    end

    def self.queries(subject)
      self.base_relation =
        if subject.is_a?(ActiveRecord::Relation)
          subject
        elsif subject < ActiveRecord::Base
          subject.all
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
          "You need to implement #query method which returns ActiveRecord::Relation object"
      )
    end
  end
end
