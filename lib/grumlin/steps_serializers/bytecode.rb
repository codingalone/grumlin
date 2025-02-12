# frozen_string_literal: true

module Grumlin
  module StepsSerializers
    class Bytecode < Serializer
      # constructor params: no_return: true|false, default false
      # TODO: add pretty

      NONE_STEP = StepData.new("none")

      def serialize
        steps = ShortcutsApplyer.call(@steps)
        no_return = @params.fetch(:no_return, false)
        {}.tap do |result|
          result[:step] = serialize_steps(steps.steps + (no_return ? [NONE_STEP] : [])) if steps.steps.any?
          result[:source] = serialize_steps(steps.configuration_steps) if steps.configuration_steps.any?
        end
      end

      private

      def serialize_steps(steps)
        steps.map { |s| serialize_step(s) }
      end

      def serialize_step(step)
        [step.name].tap do |result|
          step.args.each do |arg|
            result << serialize_arg(arg)
          end
          result << step.params if step.params.any?
        end
      end

      def serialize_arg(arg)
        return serialize_typed_value(arg) if arg.is_a?(TypedValue)
        return serialize_predicate(arg) if arg.is_a?(Expressions::P::Predicate)
        return arg.value if arg.is_a?(Expressions::WithOptions)

        return arg unless arg.is_a?(Steps)

        { :@type => "g:Bytecode", :@value => Bytecode.new(arg, **@params.merge(no_return: false)).serialize }
      end

      def serialize_typed_value(value)
        return value.value if value.type.nil?

        {
          "@type": "g:#{value.type}",
          "@value": value.value
        }
      end

      def serialize_predicate(value)
        {
          "@type": "g:#{value.namespace}",
          "@value": {
            predicate: value.name,
            value: if value.type.nil?
                     value.value
                   else
                     {
                       "@type": "g:#{value.type}",
                       "@value": value.value
                     }
                   end
          }
        }
      end
    end
  end
end
