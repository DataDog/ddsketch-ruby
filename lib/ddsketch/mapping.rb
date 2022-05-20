# from __future__ import division

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2020 Datadog, Inc.

# from abc import ABCMeta
# from abc import abstractmethod
# import Math
# import sys
#
# import six
#
# from .exception import IllegalArgumentException

module DDSketch

  # A mapping between values and integer indices that imposes relative accuracy
  # guarantees. Specifically, for any value `minIndexableValue() < value <
  # maxIndexableValue` implementations of `KeyMapping` must be such that
  # `value(key(v))` is close to `v` with a relative error that is less than
  # `relative_accuracy`.
  #
  # In implementations of KeyMapping, there is generally a trade-off between the
  # cost of computing the key and the number of keys that are required to cover a
  # given range of values (memory optimality). The most memory-optimal mapping is
  # the LogarithmicMapping, but it requires the costly evaluation of the logarithm
  # when computing the index. Other mappings can approximate the logarithmic
  # mapping, while being less computationally costly.
  #
  # @abstract
  class KeyMapping

    # Args:
    #     relative_accuracy (float): the accuracy guarantee; referred to as alpha
    #     in the paper. (0. < alpha < 1.)
    #     offset (float): an offset that can be used to shift all bin keys
    # Attributes:
    #     gamma (float): the base for the exponential buckets. gamma = (1 + alpha) / (1 - alpha)
    #     min_possible: the smallest value the sketch can distinguish from 0
    #     max_possible: the largest value the sketch can handle
    #     _multiplier (float): used for calculating log_gamma(value) initially, _multiplier = 1 / log(gamma)
    #
    # type: (float, float) -> None
    attr_reader :gamma

    def initialize(relative_accuracy, offset = 0.0)
      if relative_accuracy <= 0 or relative_accuracy >= 1
        raise IllegalArgumentException("Relative accuracy must be between 0 and 1.")
      end

      @relative_accuracy = relative_accuracy
      @offset = offset

      gamma_mantissa = 2 * relative_accuracy / (1 - relative_accuracy)
      @gamma = 1 + gamma_mantissa
      @multiplier = 1 / Math.log(gamma_mantissa + 1)
      @min_possible = Float::MIN * @gamma
      @max_possible = Float::MAX / @gamma
    end

    attr_reader :relative_accuracy, :min_possible, :max_possible

    # Constructor used by pb.proto
    # type: (float, float) -> KeyMapping
    def self.from_gamma_offset(cls, gamma, offset)
      relative_accuracy = (gamma - 1.0) / (gamma + 1.0)
      return cls(relative_accuracy, offset = offset)
    end

    # type: (float) -> int
    # """
    #       Args:
    #           value (float)
    #       Returns:
    #           int: the key specifying the bucket for value
    #       """
    def key(value)
      return Integer(self.log_gamma(value).ceil + @offset)
    end

    # type: (int) -> float
    # """
    #       Args:
    #           key (int)
    #       Returns:
    #           float: the value represented by the bucket specified by the key
    #       """
    def value(key)
      return self.pow_gamma(key - @offset) * (2.0 / (1 + @gamma))
    end

    protected

    # type: (float) -> float
    # """Return (an approximation of) the logarithm of the value base gamma"""
    # @abstract
    def log_gamma(value) end

    # # type: (float) -> float
    # """Return (an approximation of) gamma to the power value"""
    # @abstract
    def pow_gamma(value) end
  end

  # """A memory-optimal KeyMapping, i.e., given a targeted relative accuracy, it
  #     requires the least number of keys to cover a given range of values. This is
  #     done by logarithmically mapping floating-point values to integers.
  #     """
  class LogarithmicMapping < KeyMapping
    # type: (float, float) -> None
    def initialize(relative_accuracy, offset = 0.0)
      super(relative_accuracy, offset = offset)
      @multiplier *= Math.log(2)
    end

    protected

    def log_gamma(value)
      # type: (float) -> float
      return Math.log(value, 2) * @multiplier
    end

    def pow_gamma(value)
      # type: (float) -> float
      return 2 ** (value / @multiplier)
    end
  end

  # """A fast KeyMapping that approximates the memory-optimal
  #     LogarithmicMapping by extracting the floor value of the logarithm to the
  #     base 2 from the binary representations of floating-point values and
  #     linearly interpolating the logarithm in-between.
  #     """
  class LinearlyInterpolatedMapping < KeyMapping
    # """Approximates log2 by s + f
    # where v = (s+1) * 2 ** f  for s in [0, 1)
    #
    # frexp(v) returns m and e s.t.
    # v = m * 2 ** e ; (m in [0.5, 1) or 0.0)
    # so we adjust m and e accordingly
    # """
    def _log2_approx(value)
      # type: (float) -> float

      mantissa, exponent = Math.frexp(value)
      significand = 2 * mantissa - 1
      return significand + (exponent - 1)
    end

    # """Inverse of _log2_approx"""
    def _exp2_approx(value)
      # type: (float) -> float

      exponent = Integer(value.floor + 1)
      mantissa = (value - exponent + 2) / 2.0
      return Math.ldexp(mantissa, exponent)
    end

    protected

    def log_gamma(value)
      # type: (float) -> float
      return self._log2_approx(value) * @multiplier
    end

    def pow_gamma(value)
      # type: (float) -> float
      return self._exp2_approx(value / @multiplier)
    end
  end

  # """A fast KeyMapping that approximates the memory-optimal LogarithmicMapping by
  #      extracting the floor value of the logarithm to the base 2 from the binary
  #      representations of floating-point values and cubically interpolating the
  #      logarithm in-between.
  #
  #     More detailed documentation of this method can be found in:
  #     <a href="https://github.com/DataDog/sketches-java/">sketches-java</a>
  #     """
  class CubicallyInterpolatedMapping < KeyMapping
    A = 6.0 / 35.0
    B = -3.0 / 5.0
    C = 10.0 / 7.0

    def initialize(relative_accuracy, offset = 0.0)
      # type: (float, float) -> None
      super(relative_accuracy, offset = offset)
      @multiplier /= C
    end

    def _cubic_log2_approx(value)
      # type: (float) -> float
      "" "Approximates log2 using a cubic polynomial" ""
      mantissa, exponent = Math.frexp(value)
      significand = 2 * mantissa - 1
      return (
        (A * significand + B) * significand + C
      ) * significand + (exponent - 1)
    end

    def _cubic_exp2_approx(value)
      # type: (float) -> float
      # Derived from Cardano's formula
      exponent = Integer(value.floor)
      delta_0 = B * B - 3 * A * C
      delta_1 = (2.0 * B * B * B) - (9.0 * A * B * C) - (27.0 * A * A * (value - exponent))
      cardano = Math.cbrt(
        (delta_1 - ((delta_1 * delta_1 - 4 * delta_0 * delta_0 * delta_0) ** 0.5)) / 2.0)

      significand_plus_one = (
        -(B + cardano + delta_0 / cardano) / (3.0 * A) + 1.0
      )
      mantissa = significand_plus_one / 2
      return Math.ldexp(mantissa, exponent + 1)
    end

    protected

    def log_gamma(value)
      # type: (float) -> float
      return self._cubic_log2_approx(value) * @multiplier

    end

    def pow_gamma(value)
      # type: (float) -> float
      return self._cubic_exp2_approx(value / @multiplier)
    end
  end
end
