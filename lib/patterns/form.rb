require "virtus"
require "action_controller/metal/strong_parameters"

module Patterns
  class Form
    include Virtus.model
    include ActiveModel::Validations

    Error = Class.new(StandardError)
    Invalid = Class.new(Error)
    NoParamKey = Class.new(Error)

    def initialize(*args)
      attributes = args.extract_options!

      if attributes.blank? && args.last.is_a?(ActionController::Parameters)
        attributes = args.pop.to_unsafe_h
      end

      @resource = args.first

      super(build_original_attributes.merge(attributes))
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
      if resource&.respond_to?(:persisted?)
        resource.persisted?
      else
        false
      end
    end

    def model_name
      @model_name ||= Struct.
        new(:param_key).
        new(param_key)
    end

    def self.param_key(key = nil)
      if key.nil?
        @param_key
      else
        @param_key = key
      end
    end

    private

    attr_reader :resource, :form_owner

    def param_key
      param_key = self.class.param_key
      param_key ||= resource&.respond_to?(:model_name) && resource.model_name.param_key
      raise NoParamKey if param_key.blank?
      param_key
    end

    def build_original_attributes
      return {} if resource.nil?
      base_attributes = resource.respond_to?(:attributes) && resource.attributes.symbolize_keys

      self.class.attribute_set.each_with_object(base_attributes || {}) do |attribute, result|
        if result[attribute.name].blank? && resource.respond_to?(attribute.name)
          result[attribute.name] = resource.public_send(attribute.name)
        end
      end
    end

    def persist
      raise NotImplementedError, "#persist has to be implemented"
    end
  end
end
