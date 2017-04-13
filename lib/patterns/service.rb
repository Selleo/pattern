module Patterns
  class Service
    attr_reader :result

    def self.call(*args)
      new(*args).tap do |service|
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
