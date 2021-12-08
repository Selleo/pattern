module Patterns
  class Ruleset
    class EmptyRuleset < StandardError; end

    class << self
      attr_accessor :rule_names
    end

    def self.rules
      (rule_names || []).map do |rule_name|
        rule_name.to_s.classify.constantize
      end
    end

    def self.add_rule(rule_name)
      self.rule_names ||= []
      self.rule_names << rule_name.to_sym
      self
    end

    def initialize(subject = nil)
      raise EmptyRuleset if self.class.rules.empty?

      @rules = self.class.rules.map { |rule| rule.new(subject) }
    end

    def satisfied?(force: false)
      rules.all? do |rule|
        rule.satisfied? ||
          rule.not_applicable? ||
          (force && rule.forceable?)
      end
    end

    def not_satisfied?
      !satisfied?
    end

    def applicable?
      !not_applicable?
    end

    def not_applicable?
      rules.all?(&:not_applicable?)
    end

    def forceable?
      rules.all? do |rule|
        rule.forceable? ||
          rule.not_applicable? ||
          rule.satisfied?
      end
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      rules.each do |rule_or_ruleset|
        if rule_or_ruleset.is_a?(Ruleset)
          rule_or_ruleset.each(&block)
        else
          yield rule_or_ruleset
        end
      end
    end

    private

    attr_reader :rules
  end
end
