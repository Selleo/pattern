RSpec.describe Patterns::Service do
  after { Object.send(:remove_const, :DoSomething) if defined?(DoSomething) }

  describe ".call" do
    it "returns instance of service object" do
      DoSomething = Class.new(Patterns::Service) do
        def call; end
      end

      expect(DoSomething.call).to be_kind_of(DoSomething)
    end

    it "instantiates service object passing keyword arguments to constructor" do
      DoSomething = Class.new(Patterns::Service) do
        def initialize(argument_1:, argument_2:); end
        def call; end
      end

      expect {
        DoSomething.call
      }.to raise_error ArgumentError

      expect {
        DoSomething.call(argument_1: 10, argument_2: 20)
      }.not_to raise_error
    end

    it "instantiates service object passing positional arguments to constructor" do
      DoSomething = Class.new(Patterns::Service) do
        def initialize(argument_1, argument_2); end
        def call; end
      end

      expect {
        DoSomething.call
      }.to raise_error ArgumentError

      expect {
        DoSomething.call(10, 20)
      }.not_to raise_error
    end

    it "calls #call method on service object instance" do
      Spy = Class.new do
        def self.some_method; end
      end
      allow(Spy).to receive(:some_method)
      DoSomething = Class.new(Patterns::Service) do
        def call
          Spy.some_method
        end
      end

      DoSomething.call

      expect(Spy).to have_received(:some_method)
    end

    it "requires #call method to be implemented" do
      DoSomething = Class.new(Patterns::Service)

      expect {
        DoSomething.call
      }.to raise_error NotImplementedError
    end
  end

  describe "#result" do
    it "returns a result of expression within #call method" do
      DoSomething = Class.new(Patterns::Service) do
        def call
          50
        end
      end

      service = DoSomething.call
      expect(service.result).to eq 50
    end
  end
end
