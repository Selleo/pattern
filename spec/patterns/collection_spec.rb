RSpec.describe Patterns::Collection do
  after { Object.send(:remove_const, :CustomCollection) if defined?(CustomCollection) }

  it "includes Enumerable" do
    CustomCollection = Class.new(Patterns::Collection)

    expect(CustomCollection).to be < Enumerable
  end

  describe ".new" do
    it "exposes all keyword arguments using #options by default" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          [options[:arg_1], options[:arg_2]]
        end
      end

      collection = CustomCollection.new(arg_1: 20, arg_2: 30)

      expect { |b| collection.each(&b) }.to yield_successive_args(20, 30)
    end

    it "exposes first parameter using #subject by default" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          subject
        end
      end

      collection = CustomCollection.new([1, 2, 4, 8])

      expect { |b| collection.each(&b) }.to yield_successive_args(1, 2, 4, 8)
    end
  end

  describe ".from" do
    it "returns collection instance" do
      CustomCollection = Class.new(Patterns::Collection) do
      end

      collection = CustomCollection.from

      expect(collection).to be_a_kind_of(CustomCollection)
    end

    it "exposes all keyword arguments using #options by default" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          [options[:arg_1], options[:arg_2]]
        end
      end

      collection = CustomCollection.from(arg_1: 20, arg_2: 30)

      expect { |b| collection.each(&b) }.to yield_successive_args(20, 30)
    end

    it "exposes first parameter using #subject by default" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          subject
        end
      end

      collection = CustomCollection.from([1, 2, 4, 8])

      expect { |b| collection.each(&b) }.to yield_successive_args(1, 2, 4, 8)
    end
  end

  describe ".for" do
    it "returns collection instance" do
      CustomCollection = Class.new(Patterns::Collection) do
      end

      collection = CustomCollection.for

      expect(collection).to be_a_kind_of(CustomCollection)
    end

    it "exposes all keyword arguments using #options by default" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          [options[:arg_1], options[:arg_2]]
        end
      end

      collection = CustomCollection.for(arg_1: 20, arg_2: 30)

      expect { |b| collection.each(&b) }.to yield_successive_args(20, 30)
    end

    it "exposes first parameter using #subject by default" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          subject
        end
      end

      collection = CustomCollection.for([1, 2, 4, 8])

      expect { |b| collection.each(&b) }.to yield_successive_args(1, 2, 4, 8)
    end
  end

  describe "#each" do
    it "requires #collection method being implemented" do
      CustomCollection = Class.new(Patterns::Collection)

      collection = CustomCollection.new

      expect { collection.each }.to raise_error(NotImplementedError, "#collection not implemented")
    end

    it "performs #each on result of #collection" do
      CustomCollection = Class.new(Patterns::Collection) do
        private

        def collection
          [[1, "a"], [2, "b"], [3, "c"]]
        end
      end

      collection = CustomCollection.new

      expect { |b| collection.each(&b) }.to yield_successive_args([1, "a"], [2, "b"], [3, "c"])
    end
  end
end
