RSpec.describe Patterns::Rule do
  after(:each) do
    Object.send(:remove_const, :CustomRule) if defined?(CustomRule)
  end

  it 'requires subject as the first argument' do
    CustomRule = Class.new(Patterns::Rule)

    expect { CustomRule.new }.to raise_error ArgumentError
    expect { CustomRule.new(Object.new) }.not_to raise_error
  end

  it 'requires #satisfied? method to be defined' do
    InvalidCustomRule = Class.new(Patterns::Rule)
    CustomRule = Class.new(Patterns::Rule) do
      def satisfied?
        true
      end
    end

    expect { InvalidCustomRule.new(Object.new).satisfied? }.to raise_error NotImplementedError
    expect { CustomRule.new(Object.new).satisfied? }.not_to raise_error
  end

  describe '#satisfied?' do
    context 'when subject meets the conditions' do
      it 'returns true' do
        article = OpenStruct.new('published?' => true, 'deleted?' => false)

        ArticleIsPublishedRule = Class.new(Patterns::Rule) do
          def satisfied?
            subject.published?
          end

          def not_applicable?
            subject.deleted?
          end
        end

        expect(ArticleIsPublishedRule.new(article).satisfied?).to eq true
      end
    end
  end
end
