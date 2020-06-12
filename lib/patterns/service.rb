require 'ruby2_keywords'

module Patterns
  class Service
    attr_reader :result

    class << self
      ruby2_keywords def call(*args)
        new(*args).tap do |service|
          service.instance_variable_set(
            "@result",
            service.call
          )
        end
      end
    end

    def call
      raise NotImplementedError
    end
  end
end
