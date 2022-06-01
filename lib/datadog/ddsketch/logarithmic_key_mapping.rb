# frozen_string_literal: true

module Datadog
  module DDSketch
    # A memory-optimal KeyMapping, i.e., given a targeted relative accuracy, it
    # requires the least number of keys to cover a given range of values. This is
    # done by logarithmically mapping floating-point values to integers.
    class LogarithmicKeyMapping < KeyMapping
      def initialize(
        relative_accuracy:,
        offset: 0.0
      )
        super(relative_accuracy: relative_accuracy, offset: offset)
        @multiplier *= Math.log(2)
      end

      protected

      def log_gamma(value)
        Math.log(value, 2) * @multiplier
      end

      def pow_gamma(value)
        2**(value / @multiplier)
      end
    end
  end
end
