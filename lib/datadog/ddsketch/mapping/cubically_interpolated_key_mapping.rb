# frozen_string_literal: true

module Datadog
  module DDSketch
    module Mapping
      # A fast KeyMapping that approximates the memory-optimal LogarithmicMapping by
      # extracting the floor value of the logarithm to the base 2 from the binary
      # representations of floating-point values and cubically interpolating the
      # logarithm in-between.

      # More detailed documentation of this method can be found in:
      # <a href="https://github.com/DataDog/sketches-java/">sketches-java</a>
      class CubicallyInterpolatedKeyMapping < KeyMapping
        A = 6.0 / 35.0
        B = -3.0 / 5.0
        C = 10.0 / 7.0

        def initialize(relative_accuracy:, offset: 0.0)
          super(relative_accuracy: relative_accuracy, offset: offset)

          @multiplier /= C
        end

        # Approximates log2 using a cubic polynomial
        def _cubic_log2_approx(value)
          mantissa, exponent = Math.frexp(value)
          significand = 2 * mantissa - 1
          (
            (A * significand + B) * significand + C
          ) * significand + (exponent - 1)
        end

        def _cubic_exp2_approx(value)
          exponent = Integer(value.floor)
          delta_0 = B * B - 3 * A * C
          delta_1 = (2.0 * B * B * B) - (9.0 * A * B * C) - (27.0 * A * A * (value - exponent))
          cardano = Math.cbrt(
            (delta_1 - ((delta_1 * delta_1 - 4 * delta_0 * delta_0 * delta_0)**0.5)) / 2.0
          )

          significand_plus_one = (
            -(B + cardano + delta_0 / cardano) / (3.0 * A) + 1.0
          )
          mantissa = significand_plus_one / 2

          # JRuby has inconsistent result with `Math.ldexp`
          # https://github.com/jruby/jruby/issues/7234
          Math.ldexp(mantissa, exponent + 1)
        end

        def to_proto
          Proto::IndexMapping.new(
            gamma: @relative_accuracy,
            indexOffset: @offset,
            interpolation: Proto::IndexMapping::Interpolation::CUBIC
          )
        end

        protected

        def log_gamma(value)
          _cubic_log2_approx(value) * @multiplier
        end

        def pow_gamma(value)
          _cubic_exp2_approx(value / @multiplier)
        end
      end
    end
  end
end
