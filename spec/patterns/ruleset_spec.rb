RSpec.describe Ruleset do
  context 'when empty ruleset is initialized' do
    it 'raises an error' do
      empty_ruleset_klass = Class.new(Ruleset)
      custom_ruleset_klass = Class.new(Ruleset)
      subject = double

      with_mocked_rules do |rules|
        rules << mock_rule(:rule_1)
        custom_ruleset_klass.add_rule(:rule_1)

        expect { custom_ruleset_klass.new(subject) }.not_to raise_error
      end

      expect { empty_ruleset_klass.new(subject) }.to raise_error Ruleset::EmptyRuleset
    end
  end

  describe '#forceable?' do
    context 'all rules are forceable' do
      it 'returns true' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1, is_forceable: true)
          rules << mock_rule(:rule_2, is_forceable: true)

          custom_ruleset_klass = Class.new(Ruleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).forceable?).to eq true
        end
      end
    end

    context 'at least one rule is not forceable' do
      it 'returns false' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1, is_forceable: false, is_satisfied: false, is_applicable: true)
          rules << mock_rule(:rule_2, is_forceable: true)

          custom_ruleset_klass = Class.new(Ruleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).forceable?).to eq false
        end
      end

      context 'and rule is satisfied' do
        it 'returns true' do
          with_mocked_rules do |rules|
            subject = double
            rules << mock_rule(
              :rule_1,
              is_forceable: false,
              is_satisfied: true,
              is_applicable: true
            )
            rules << mock_rule(:rule_2, is_forceable: true)

            custom_ruleset_klass = Class.new(Ruleset)
            custom_ruleset_klass.add_rule(:rule_1)
            custom_ruleset_klass.add_rule(:rule_2)

            expect(custom_ruleset_klass.new(subject).forceable?).to eq true
          end
        end
      end

      context 'and rule is not applicable' do
        it 'returns true' do
          with_mocked_rules do |rules|
            subject = double
            rules << mock_rule(
              :rule_1,
              is_forceable: false,
              is_satisfied: false,
              is_applicable: false
            )
            rules << mock_rule(:rule_2, is_forceable: true)

            custom_ruleset_klass = Class.new(Ruleset)
            custom_ruleset_klass.add_rule(:rule_1)
            custom_ruleset_klass.add_rule(:rule_2)

            expect(custom_ruleset_klass.new(subject).forceable?).to eq true
          end
        end
      end
    end
  end

  describe '#not_applicable?' do
    context 'all rules are not applicable' do
      it 'returns true' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1, is_applicable: false)
          rules << mock_rule(:rule_2, is_applicable: false)

          custom_ruleset_klass = Class.new(Ruleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).not_applicable?).to eq true
        end
      end
    end

    context 'at least one rule is applicable' do
      it 'returns false' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1, is_applicable: false)
          rules << mock_rule(:rule_2, is_applicable: true)

          custom_ruleset_klass = Class.new(Ruleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).not_applicable?).to eq false
        end
      end
    end
  end

  describe '#satisfied?' do
    context 'all rules are satisfied' do
      it 'returns true' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1)
          rules << mock_rule(:rule_2)

          custom_ruleset_klass = Class.new(Ruleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).satisfied?).to eq true
        end
      end
    end

    context 'at least one rule is not satisfied' do
      it 'returns false' do
        with_mocked_rules do |rules|
          subject = double
          rules << mock_rule(:rule_1)
          rules << mock_rule(:rule_2, is_satisfied: false)

          custom_ruleset_klass = Class.new(Ruleset)
          custom_ruleset_klass.add_rule(:rule_1)
          custom_ruleset_klass.add_rule(:rule_2)

          expect(custom_ruleset_klass.new(subject).satisfied?).to eq false
        end
      end

      context 'when rule is not applicable' do
        it 'returns true' do
          with_mocked_rules do |rules|
            subject = double
            rules << mock_rule(:rule_1)
            rules << mock_rule(:rule_2, is_satisfied: false, is_applicable: false)

            custom_ruleset_klass = Class.new(Ruleset)
            custom_ruleset_klass.add_rule(:rule_1)
            custom_ruleset_klass.add_rule(:rule_2)

            expect(custom_ruleset_klass.new(subject).satisfied?).to eq true
          end
        end
      end

      context 'when provided with force: true' do
        context 'when rule is forceable' do
          it 'returns true' do
            with_mocked_rules do |rules|
              subject = double
              rules << mock_rule(:rule_1)
              rules << mock_rule(:rule_2, is_satisfied: false, is_forceable: true)

              custom_ruleset_klass = Class.new(Ruleset)
              custom_ruleset_klass.add_rule(:rule_1)
              custom_ruleset_klass.add_rule(:rule_2)

              expect(custom_ruleset_klass.new(subject).satisfied?(force: true)).to eq true
            end
          end
        end

        context 'when rule is not forceable' do
          it 'returns false' do
            with_mocked_rules do |rules|
              subject = double
              rules << mock_rule(:rule_1)
              rules << mock_rule(:rule_2, is_satisfied: false, is_forceable: false)

              custom_ruleset_klass = Class.new(Ruleset)
              custom_ruleset_klass.add_rule(:rule_1)
              custom_ruleset_klass.add_rule(:rule_2)

              expect(custom_ruleset_klass.new(subject).satisfied?(force: true)).to eq false
            end
          end
        end
      end
    end
  end

  describe '#each' do
    it 'yields all rules for ruleset' do
      with_mocked_rules do |rules|
        rules << (_, rule_1 = mock_rule(:rule_1))
        rules << (_, rule_2 = mock_rule(:rule_2))
        rules << (_, rule_3 = mock_rule(:rule_3))
        custom_ruleset_klass_1 = Class.new(Ruleset)
        custom_ruleset_klass_1.add_rule(:rule_1)
        custom_ruleset_klass_1.add_rule(:rule_2)
        Ruleset2 = Class.new(Ruleset)
        Ruleset2.add_rule(:rule_3)
        custom_ruleset_klass_1.add_rule(:ruleset_2)

        ruleset = custom_ruleset_klass_1.new(double)

        expect { |b| ruleset.each(&b) }.to yield_successive_args(rule_1, rule_2, rule_3)
      ensure
        remove_class(Ruleset2)
      end
    end
  end

  private

  def mock_rule(rule_name, is_applicable: true, is_satisfied: true, is_forceable: true)
    klass = Object.const_set(rule_name.to_s.classify, Class.new(Rule))
    rule = double(
      not_applicable?: !is_applicable,
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
