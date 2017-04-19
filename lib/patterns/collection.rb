module Patterns
  class Collection
    include Enumerable

    def initialize(*args)
      @options = args.extract_options!
      @subject = args.first
    end

    def each
      collection.each do |*args|
        yield(*args)
      end
    end

    class << self
      alias from new
      alias for new
    end

    private

    attr_reader :options, :subject

    def collection
      raise NotImplementedError, "#collection not implemented"
    end
  end
end
