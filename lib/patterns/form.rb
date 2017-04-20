require "virtus"

module Patterns
  class Form
    include Virtus.model
    include ActiveModel::Validations

    Error = Class.new(StandardError)
    Invalid = Class.new(Error)

    def initialize(*args)
      attributes = args.extract_options!
      @resource = args.first
      super(attributes)
    end

    def save
      valid? ? persist : false
    end

    def save!
      save.tap do |saved|
        raise Invalid unless saved
      end
    end

    def as(form_owner)
      @form_owner = form_owner
      self
    end

    def to_key
      nil
    end

    def to_partial_path
      nil
    end

    def to_model
      self
    end

    def persisted?
      false
    end

    def model_name
      @model_name ||= Struct.
        new(:param_key).
        new(resource.model_name.param_key)
    end

    private

    attr_reader :resource

    def persist
      raise NotImplementedError, "#persist has to be implemented"
    end
  end
end
