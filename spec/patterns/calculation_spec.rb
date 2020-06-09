RSpec.describe Patterns::Calculation do
  before(:all) do
    class Rails
      def self.cache
        @cache ||= ActiveSupport::Cache::MemoryStore.new
      end
    end
  end

  after(:all) do
    ActiveSupport::Cache::RedisCacheStore.new.clear
    Object.send(:remove_const, :Rails)
  end

  after do
    Object.send(:remove_const, :CustomCalculation) if defined?(CustomCalculation)
    Rails.cache.clear
  end

  describe ".result" do
    it "returns a result of the calculation within a #result method" do
      CustomCalculation = Class.new(Patterns::Calculation) do
        private

        def result
          50
        end
      end

      expect(CustomCalculation.result).to eq 50
    end

    it "#result, #result_for and #calculate are aliases" do
      CustomCalculation = Class.new(Patterns::Calculation)

      expect(CustomCalculation.method(:result)).to eq CustomCalculation.method(:result_for)
      expect(CustomCalculation.method(:result)).to eq CustomCalculation.method(:calculate)
    end

    it "exposes the first argument as a subject" do
      CustomCalculation = Class.new(Patterns::Calculation) do
        private

        def result
          subject
        end
      end

      expect(CustomCalculation.result('test')).to eq 'test'
    end

    it "exposes all keyword arguments using #options" do
      CustomCalculation = Class.new(Patterns::Calculation) do
        private

        def result
          [options[:arg_1], options[:arg_2]]
        end
      end

      expect(CustomCalculation.result(nil, arg_1: 20, arg_2: 30)).to eq([20, 30])
    end
  end

  describe "caching" do
    it "caches result for 'set_cache_expiry_every' period" do
      travel_to DateTime.new(2017, 1, 1, 12, 0) do
        CustomCalculation = Class.new(Patterns::Calculation) do
          set_cache_expiry_every 1.hour

          class_attribute :counter
          self.counter = 0

          private

          def result
            self.class.counter += 1
          end
        end

        expect(CustomCalculation.result).to eq 1
        expect(CustomCalculation.result).to eq 1
      end

      travel_to DateTime.new(2017, 1, 1, 13, 1) do
        expect(CustomCalculation.result).to eq 2
        expect(CustomCalculation.result).to eq 2
      end
    end

    it "caches result for every option passed" do
      CustomCalculation = Class.new(Patterns::Calculation) do
        set_cache_expiry_every 1.hour

        class_attribute :counter
        self.counter = 0

        private

        def result
          self.class.counter += 1
        end
      end

      expect(CustomCalculation.result(123)).to eq 1
      expect(CustomCalculation.result(123)).to eq 1
      expect(CustomCalculation.result(1024)).to eq 2
      expect(CustomCalculation.result(1024)).to eq 2
      expect(CustomCalculation.result(1024, arg: 1)).to eq 3
      expect(CustomCalculation.result(1024, arg: 1)).to eq 3
    end

    it "caches result for every option passed dependant on the class" do
      CustomCalculation = Class.new(Patterns::Calculation) do
        set_cache_expiry_every 1.hour

        class_attribute :counter
        self.counter = 0

        private

        def result
          self.class.counter += 1
        end
      end

      DifferentCalculation = Class.new(Patterns::Calculation) do
        set_cache_expiry_every 1.hour

        class_attribute :counter
        self.counter = 100

        private

        def result
          self.class.counter += 1
        end
      end

      expect(CustomCalculation.result(123)).to eq 1
      expect(CustomCalculation.result(123)).to eq 1
      expect(DifferentCalculation.result(123)).to eq 101
      expect(DifferentCalculation.result(123)).to eq 101

      Object.send(:remove_const, :DifferentCalculation)
    end

    it "does not cache result if 'set_cache_expiry_every' is not set" do
      CustomCalculation = Class.new(Patterns::Calculation) do
        class_attribute :counter
        self.counter = 0

        private

        def result
          self.class.counter += 1
        end
      end

      expect(CustomCalculation.result).to eq 1
      expect(CustomCalculation.result).to eq 2
    end

    describe "when RedisCacheStore is used" do
      it "does not store data in cache if 'cache_expiry_period is not set'" do
        client = Redis.new
        class Rails
          def self.cache
            @cache ||= ActiveSupport::Cache::RedisCacheStore.new
          end
        end

        CustomCalculation = Class.new(Patterns::Calculation) do
          class_attribute :counter
          self.counter = 0

          private

          def result
            self.class.counter += 1
          end
        end

        expect(CustomCalculation.result).to eq 1
        expect(CustomCalculation.result).to eq 2
        expect(client.keys).to be_empty
      end
    end

    it "uses cache keys consistent between processes" do
      rails_mock = <<~RUBY
        class Rails
          def self.cache
            @cache ||= ActiveSupport::Cache::RedisCacheStore.new
          end
        end
      RUBY

      klass = <<~RUBY
        require 'active_support/all'
        require 'active_support/testing/time_helpers'
        require_relative 'rails_mock'
        require_relative '../../lib/patterns/calculation'
        CustomCalculation = Class.new(Patterns::Calculation) do
          set_cache_expiry_every 1.hour
          class_attribute :counter
          self.counter = 0
          private
          def result
            self.class.counter += 1
          end
        end
      RUBY

      script = <<~RUBY
        require_relative 'rails_mock'
        require_relative 'custom_calculation'
        CustomCalculation.result
      RUBY

      `mkdir -p tmp/spec`
      `echo "#{klass}" > tmp/spec/custom_calculation.rb`
      `echo "#{script}" > tmp/spec/calculation_script.rb`
      `echo "#{rails_mock}" > tmp/spec/rails_mock.rb`
      `bundle exec ruby tmp/spec/custom_calculation.rb`

      Process.spawn('bundle exec ruby tmp/spec/calculation_script.rb')
      Process.spawn('bundle exec ruby tmp/spec/calculation_script.rb')
      Process.spawn('bundle exec ruby tmp/spec/calculation_script.rb')
      Process.waitall

      expect(Redis.new.keys.length).to eq 1
      `rm -rf tmp/spec`
    end
  end
end
