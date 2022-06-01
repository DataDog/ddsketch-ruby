# frozen_string_literal: true

module Datadog
  module DDSketch
    # A fast KeyMapping that approximates the memory-optimal
    # LogarithmicMapping by extracting the floor value of the logarithm to the
    # base 2 from the binary representations of floating-point values and
    # linearly interpolating the logarithm in-between.
    class LinearlyInterpolatedKeyMapping < KeyMapping

      # Approximates log2 by s + f
      # where v = (s+1) * 2 ** f  for s in [0, 1)

      # frexp(v) returns m and e s.t.
      # v = m * 2 ** e ; (m in [0.5, 1) or 0.0)
      # so we adjust m and e accordingly
      def _log2_approx(value)
        mantissa, exponent = Math.frexp(value)
        significand = 2 * mantissa - 1

        significand + (exponent - 1)
      end

      def _exp2_approx(value)
        exponent = Integer(value.floor + 1)
        mantissa = (value - exponent + 2) / 2.0

        # JRuby has inconsistent result with `Math.ldexp`
        # https://github.com/jruby/jruby/issues/7234
        Math.ldexp(mantissa, exponent)
      end

      protected

      def log_gamma(value)
        _log2_approx(value) * @multiplier
      end

      def pow_gamma(value)
        _exp2_approx(value / @multiplier)
      end
    end
  end
end
