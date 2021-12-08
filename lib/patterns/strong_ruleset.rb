# StrongRuleset is not satisfied and not forceable if any of rules is not applicable

module Patterns
  class StrongRuleset < Ruleset
    def satisfied?(force: false)
      rules.all? do |rule|
        (rule.applicable? && rule.satisfied?) || (force && rule.forceable?)
      end
    end

    def not_applicable?
      rules.any?(&:not_applicable?)
    end

    def forceable?
      rules.all? do |rule|
        (rule.applicable? && rule.forceable?) || rule.satisfied?
      end
    end
  end
end
