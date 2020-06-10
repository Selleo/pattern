module Patterns
  class Service
    attr_reader :result

    def self.call(*args, **kwargs, &block)
      new(*args, **kwargs, &block).tap do |service|
        service.instance_variable_set(
          "@result",
          service.call
        )
      end
    end

    def call
      raise NotImplementedError
    end
  end
end
