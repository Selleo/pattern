RSpec.describe Patterns::StrongRuleset do
  it 'inherites from Ruleset' do
    custom_strong_ruleset_klass = Class.new(Patterns::StrongRuleset)
    expect(custom_strong_ruleset_klass.ancestors).to include Patterns::Ruleset
  end

  context 'when any of rules is not applicable' do
    it 'is not satisfied' do
      with_mocked_rules do |rules|
        subject = double
        rules << mock_rule(:rule_1, is_applicable: false)
        rules << mock_rule(:rule_2)

        custom_ruleset_klass = Class.new(Patterns::StrongRuleset)
        custom_ruleset_klass.add_rule(:rule_1)
        custom_ruleset_klass.add_rule(:rule_2)

        expect(custom_ruleset_klass.new(subject).satisfied?).to eq false
      end
    end

    context 'when not applicable rule is not satisfied' do
      it 'is not forceable' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1, is_applicable: false, is_satisfied: false)
          rules << mock_rule(:rule_2)

          custom_ruleset_klass = Class.new(Patterns::StrongRuleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).forceable?).to eq false
        end
      end
    end

    it 'is not applicable' do
      with_mocked_rules do |rules|
        subject = double
        rules << mock_rule(:rule_1, is_applicable: false)
        rules << mock_rule(:rule_2)

        custom_ruleset_klass = Class.new(Patterns::StrongRuleset)
        custom_ruleset_klass.add_rule(:rule_1)
        custom_ruleset_klass.add_rule(:rule_2)

        expect(custom_ruleset_klass.new(subject).applicable?).to eq false
      end
    end
  end

  private

  def mock_rule(rule_name, is_applicable: true, is_satisfied: true, is_forceable: true)
    klass = Object.const_set(rule_name.to_s.classify, Class.new(Patterns::Rule))
    rule = double(
      not_applicable?: !is_applicable,
      applicable?: is_applicable,
      satisfied?: is_satisfied,
      forceable?: is_forceable
    )
    allow(klass).to receive(:new).with(anything) { rule }
    [klass, rule]
  end

  def with_mocked_rules
    rules_storage = []
    yield rules_storage
  ensure
    rules_storage.each do |rule_klass, _rule_instance|
      remove_class(rule_klass)
    end
  end

  def remove_class(klass)
    Object.send(:remove_const, klass.name.to_sym)
  end
end
