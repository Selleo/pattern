RSpec.describe Patterns::Query do
  after { Object.send(:remove_const, :CustomQuery) if defined?(CustomQuery) }

  describe '.new' do
    it 'accepts a relation only as argument' do
      CustomQuery = Class.new(Patterns::Query)

      expect {
        CustomQuery.new([1, 2, 3])
      }.to raise_error(
        Patterns::Query::RelationRequired,
        'Queries accept only ActiveRecord::Relation as input'
      )
    end

    it 'accepts a relation only as keyword positional arguments' do
      CustomQuery = Class.new(Patterns::Query) do
        def initialize(a); end

        def query
          ActiveRecord::Relation.allocate
        end
      end

      expect { CustomQuery.call([1, 2]) }.not_to raise_error
    end

    it 'accepts a relation only as keyword arguments' do
      CustomQuery = Class.new(Patterns::Query) do
        def initialize(a:); end

        def query
          ActiveRecord::Relation.allocate
        end
      end

      expect { CustomQuery.call(a: [1, 2]) }.not_to raise_error
    end

    it 'requires an argument' do
      CustomQuery = Class.new(Patterns::Query)

      expect {
        CustomQuery.new
      }.to raise_error(
        Patterns::Query::RelationRequired,
        'Queries require a base relation defined. Use .queries method to define relation.'
      )
    end

    it 'initializes a query object' do
      CustomQuery = Class.new(Patterns::Query)
      relation = ActiveRecord::Relation.allocate

      query = CustomQuery.new(relation)

      expect(query).to be_a_kind_of(CustomQuery)
    end
  end

  describe '.call' do
    it 'calls #call and passes argument to constructor' do
      CustomQuery = Class.new(Patterns::Query)
      relation = ActiveRecord::Relation.allocate
      result_relation = ActiveRecord::Relation.allocate
      query_double = instance_double(CustomQuery)
      allow(CustomQuery).to receive(:new) { query_double }
      allow(query_double).to receive(:call) { result_relation }

      result = CustomQuery.call(relation)

      expect(result).to eql result_relation
      expect(query_double).to have_received(:call)
    end
  end

  describe '#call' do
    it 'requires impementing #query method' do
      relation =  ActiveRecord::Relation.allocate
      CustomQuery = Class.new(Patterns::Query)

      expect {
        CustomQuery.new(relation).call
      }.to raise_error(
        NotImplementedError,
        'You need to implement #query method which returns ActiveRecord::Relation object'
      )
    end

    it 'returns result of calling #query' do
      relation = ActiveRecord::Relation.allocate
      result_relation = ActiveRecord::Relation.allocate
      CustomQuery = Class.new(Patterns::Query) do
        attr_accessor :internal_query

        def query
          internal_query
        end
      end

      query = CustomQuery.new(relation)
      query.internal_query = result_relation
      result = query.call

      expect(result).to eql result_relation
    end

    it 'ensures that #query returns a relation' do
      relation = ActiveRecord::Relation.allocate
      CustomQuery = Class.new(Patterns::Query) do
        def query
          [1, 2, 3]
        end
      end

      expect {
        CustomQuery.call(relation)
      }.to raise_error(
        Patterns::Query::RelationRequired,
        '#query method should return object of ActiveRecord::Relation class'
      )
    end
  end
end
