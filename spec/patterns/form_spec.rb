RSpec.describe Patterns::Form do
  after { Object.send(:remove_const, :CustomForm) if defined?(CustomForm) }

  it "includes Virtus.model" do
    CustomForm = Class.new(Patterns::Form)

    expect(CustomForm.attribute_set).to be_kind_of(Virtus::AttributeSet)
  end

  it "includes ActiveModel::Validations" do
    CustomForm = Class.new(Patterns::Form)

    expect(CustomForm).to be < ActiveModel::Validations
  end

  describe ".new" do
    it "returns form instance" do
      CustomForm = Class.new(Patterns::Form)

      form = CustomForm.new(double)

      expect(form).to be_a_kind_of(CustomForm)
    end

    it "assigns form attributes with values passed as second argument" do
      CustomForm = Class.new(Patterns::Form) do
        attribute :first_name, String
        attribute :last_name, String
      end

      form = CustomForm.new({ first_name: "Tony", last_name: "Stark" })

      expect(form.first_name).to eq "Tony"
      expect(form.last_name).to eq "Stark"
    end

    it "can be initialized without providing resource" do
      CustomForm = Class.new(Patterns::Form)

      form = CustomForm.new

      expect(form).to be_a_kind_of(CustomForm)
    end

    context "when resource exists" do
      context "when resource responds to #attributes" do
        it "assigns merged attributes from resource and passed as argument" do
          CustomForm = Class.new(Patterns::Form) do
            attribute :first_name, String
            attribute :last_name, String
          end
          resource = double(attributes: { first_name: "Jack", last_name: "Black" })

          form = CustomForm.new(resource, { first_name: "Tony" })

          expect(form.first_name).to eq "Tony"
          expect(form.last_name).to eq "Black"
        end
      end

      context "when resource does not respond to #attributes" do
        it "assigns attributes passed as argument only" do
          CustomForm = Class.new(Patterns::Form) do
            attribute :first_name, String
            attribute :last_name, String
          end

          form = CustomForm.new(double, { first_name: "Tony" })

          expect(form.first_name).to eq "Tony"
          expect(form.last_name).to eq nil
        end
      end
    end
  end

  describe "#save" do
    context "when form is valid" do
      it "requires #persist method to be implemented" do
        CustomForm = Class.new(Patterns::Form)

        form = CustomForm.new(double)

        expect { form.save }.to raise_error NotImplementedError, "#persist has to be implemented"
      end

      it "returns result of #persist method" do
        CustomForm = Class.new(Patterns::Form) do
          private

          def persist
            10
          end
        end

        form = CustomForm.new(double)
        result = form.save

        expect(result).to eq 10
      end
    end

    context "when form is invalid" do
      it "does not call #persist method" do
        CustomForm = Class.new(Patterns::Form) do
          private

          def persist
            raise StandardError, "Should not be raised!"
          end
        end
        form = CustomForm.new(double)
        allow(form).to receive(:valid?) { false }

        expect { form.save }.to_not raise_error
      end

      it "returns false" do
        CustomForm = Class.new(Patterns::Form) do
          private

          def persist
            10
          end
        end
        form = CustomForm.new(double)
        allow(form).to receive(:valid?) { false }

        expect(form.save).to eq false
      end
    end
  end

  describe "#save!" do
    context "#save returned falsey value" do
      it "returns Pattern::Form::Invalid exception" do
        CustomForm = Class.new(Patterns::Form) do
          private

          def persist
            10
          end
        end
        form = CustomForm.new(double)
        allow(form).to receive(:save) { false }

        expect { form.save! }.to raise_error Patterns::Form::Invalid
      end
    end

    context "#save returned truthy value" do
      it "returns value returned from #save" do
        CustomForm = Class.new(Patterns::Form) do
          private

          def persist
            10
          end
        end
        form = CustomForm.new(double)

        expect(form.save!).to eq 10
      end
    end
  end

  describe "#as" do
    it "saves argument in @form_owner" do
      CustomForm = Class.new(Patterns::Form)
      form_owner = double("Form owner")

      form = CustomForm.new(double).as(form_owner)

      expect(form.instance_variable_get("@form_owner")).to eq form_owner
    end

    it "returns itself" do
      CustomForm = Class.new(Patterns::Form)

      form = CustomForm.new(double)
      result = form.as(double)

      expect(result).to eq form
    end
  end

  describe "#persisted?" do
    context "when resource is nil" do
      it "returns false" do
        CustomForm = Class.new(Patterns::Form)

        form = CustomForm.new

        expect(form.persisted?).to eq false
      end
    end

    context "when resource is not nil" do
      context "when resource responds to #persisted?" do
        it "returns resource#persisted?" do
          CustomForm = Class.new(Patterns::Form)

          form_1 = CustomForm.new(double(persisted?: true))
          form_2 = CustomForm.new(double(persisted?: false))

          expect(form_1.persisted?).to eq true
          expect(form_2.persisted?).to eq false
        end
      end

      context "when resource does not respond to #persisted?" do
        it "returns false" do
          CustomForm = Class.new(Patterns::Form)

          form = CustomForm.new(double)

          expect(form.persisted?).to eq false
        end
      end
    end
  end

  describe "#to_model" do
    it "retruns itself" do
      CustomForm = Class.new(Patterns::Form)

      form = CustomForm.new(double)

      expect(form.to_model).to eq form
    end
  end

  describe "#to_partial_path" do
    it "returns nil" do
      CustomForm = Class.new(Patterns::Form)

      form = CustomForm.new(double)

      expect(form.to_partial_path).to eq nil
    end
  end

  describe "#to_key" do
    it "returns nil" do
      CustomForm = Class.new(Patterns::Form)

      form = CustomForm.new(double)

      expect(form.to_key).to eq nil
    end
  end

  describe "#model_name" do
    it "returns object responding to #param_key returning resource#param_key" do
      CustomForm = Class.new(Patterns::Form)
      resource = double(model_name: double(param_key: "resource_key"))

      form = CustomForm.new(resource)
      result = form.model_name

      expect(result).to respond_to(:param_key)
      expect(result.param_key).to eq "resource_key"
    end
  end
end
