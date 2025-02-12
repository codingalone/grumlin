# frozen_string_literal: true

RSpec.describe Grumlin::Action do
  let(:action_class) { shortcuts.action_class }
  let(:action) { action_class.new(name, args: args, params: params) }
  let(:name) { :V }
  let(:args) { [] }
  let(:params) { {} }
  let(:shortcuts) { Grumlin::Shortcuts::Storage.empty }

  describe "chaining" do
    context "when no shortcuts are used" do
      it "chains" do
        configuration_step = action_class.new(:withSideEffect, args: [:a], params: { a: 1 })
        expect(configuration_step.previous_step).to be_nil
        expect(configuration_step).to be_an(action_class)
        expect(configuration_step.name).to eq(:withSideEffect)
        expect(configuration_step.args).to eq([:a])
        expect(configuration_step.params).to eq({ a: 1 })

        start_step = configuration_step.V
        expect(start_step).to be_an(action_class)
        expect(start_step.name).to eq(:V)
        expect(start_step.args).to be_empty
        expect(start_step.params).to be_empty

        regular_step = start_step.has(:property, :value)
        expect(regular_step).to be_an(action_class)
        expect(regular_step.name).to eq(:has)
        expect(regular_step.args).to eq(%i[property value])
        expect(regular_step.params).to be_empty

        expect(regular_step.previous_step).to equal(start_step)
        expect(regular_step.previous_step.previous_step).to equal(configuration_step)
      end
    end

    context "when shortcuts are used" do
      subject { action.foo(:arg1, :arg2, param1: 1, param2: 2) }

      let(:shortcuts) { Grumlin::Shortcuts::Storage[{ foo: Grumlin::Shortcut.new(:foo) { nil } }] }

      context "when shortcut is empty" do
        it "returns an Action" do
          expect(subject).to be_an(action_class)
        end

        it "assigns passes args and params to the new Action" do
          expect(subject.args).to eq(%i[arg1 arg2])
          expect(subject.params).to eq({ param1: 1, param2: 2 })
        end

        it "assigns previous_step" do
          expect(subject.previous_step).to equal(action)
        end
      end
    end
  end

  describe "#step" do
    subject { action.step("step", :arg1, :arg2, param1: 1, param2: 2) }

    it "returns an Action" do
      expect(subject).to be_an(action_class)
    end

    it "assigns passes args and params to the new Action" do
      expect(subject.args).to eq(%i[arg1 arg2])
      expect(subject.params).to eq({ param1: 1, param2: 2 })
    end

    it "assigns previous_step" do
      expect(subject.previous_step).to equal(action)
    end
  end

  describe "#configuration_step?" do
    subject { action.configuration_step? }

    context "when step is a configuration step" do
      let(:name) { "withSideEffect" }

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when step is not a configuration_step" do
      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#start_step?" do
    subject { action.start_step? }

    context "when step a start step" do
      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when step is not a configuration_step" do
      let(:name) { "withSideEffect" }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#regular_step?" do
    subject { action.regular_step? }

    context "when step a regular step" do
      let(:name) { :has }

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when step is not a configuration_step" do
      let(:name) { "withSideEffect" }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#supported_step?" do
    subject { action.supported_step? }

    context "when step is supported" do
      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when step is not supported" do
      let(:name) { "some_step" }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#shortcut" do
    subject { action.shortcut }

    context "when step is a shortcut" do
      let(:shortcuts) { Grumlin::Shortcuts::Storage[{ cut: Grumlin::Shortcut.new(:name) { nil } }] }
      let(:name) { :cut }

      it "returns a Shortcut" do
        expect(subject).to be_a(Grumlin::Shortcut)
      end
    end

    context "when step is no a shortcut" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#==" do
    subject { action == other_action }

    context "when name, args, params and previous step are equal" do
      let(:action) { action_class.new(:V).has(:property, :value).where(action_class.new(:has, args: %i[property value])) }
      let(:other_action) { action_class.new(:V).has(:property, :value).where(action_class.new(:has, args: %i[property value])) }

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when something is not equal" do
      let(:action) { action_class.new(:V).has(:property, :value).where(action_class.new(:has, args: %i[property value])) }
      let(:other_action) { action_class.new(:V).has(:property, :value).where(action_class.new(:V, args: [:id])) }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#steps" do
    subject { action.steps }

    it "returns steps" do
      expect(subject).to be_an(Grumlin::Steps)
    end
  end
end
