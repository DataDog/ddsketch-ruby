# frozen_string_literal: true

module Datadog
  module DDSketch
    module Mapping
      # A mapping between values and integer indices that imposes relative accuracy
      # guarantees. Specifically, for any value `minIndexableValue() < value <
      # maxIndexableValue` implementations of `KeyMapping` must be such that
      # `value(key(v))` is close to `v` with a relative error that is less than
      # `relative_accuracy`.

      # In implementations of KeyMapping, there is generally a trade-off between the
      # cost of computing the key and the number of keys that are required to cover a
      # given range of values (memory optimality). The most memory-optimal mapping is
      # the LogarithmicMapping, but it requires the costly evaluation of the logarithm
      # when computing the index. Other mappings can approximate the logarithmic
      # mapping, while being less computationally costly.
      class KeyMapping
        attr_reader :gamma, :relative_accuracy, :min_possible, :max_possible

        def initialize(relative_accuracy:, offset: 0.0)
          if (relative_accuracy <= 0) || (relative_accuracy >= 1)
            raise ArgumentError, 'Relative accuracy must be between 0 and 1.'
          end

          @relative_accuracy = relative_accuracy
          @offset = offset

          gamma_mantissa = 2 * relative_accuracy / (1 - relative_accuracy)

          @gamma = 1 + gamma_mantissa
          @multiplier = 1 / Math.log(gamma_mantissa + 1)
          @min_possible = Float::MIN * @gamma
          @max_possible = Float::MAX / @gamma
        end

        def key(value)
          Integer(log_gamma(value).ceil + @offset)
        end

        def value(key)
          pow_gamma(key - @offset) * (2.0 / (1 + @gamma))
        end

        protected

        def log_gamma(value) end

        def pow_gamma(value) end
      end
    end
  end
end
