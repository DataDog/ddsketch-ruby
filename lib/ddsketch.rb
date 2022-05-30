# frozen_string_literal: true

# Unless explicitly stated otherwise all files in this repository are licensed  under the Apache License 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/). Copyright 2021 Datadog, Inc.

# A quantile sketch with relative-error guarantees. This sketch computes
# quantile values with an approximation error that is relative to the actual
# quantile value. It works on both negative and non-negative input values.
#
# For instance, using DDSketch with a relative accuracy guarantee set to 1%, if
# the expected quantile value is 100, the computed quantile value is guaranteed to
# be between 99 and 101. If the expected quantile value is 1000, the computed
# quantile value is guaranteed to be between 990 and 1010.
#
# DDSketch works by mapping floating-point input values to bins and counting the
# number of values for each bin. The underlying structure that keeps track of bin
# counts is store.
#
# The memory size of the sketch depends on the range that is covered by the input
# values: the larger that range, the more bins are needed to keep track of the
# input values. As a rough estimate, if working on durations with a relative
# accuracy of 2%, about 2kB (275 bins) are needed to cover values between 1
# millisecond and 1 minute, and about 6kB (802 bins) to cover values between 1
# nanosecond and 1 day.
#
# The size of the sketch can be have a fail-safe upper-bound by using collapsing
# stores. As shown in
# <a href="http://www.vldb.org/pvldb/vol12/p2195-masson.pdf">the DDSketch paper</a>
# the likelihood of a store collapsing when using the default bound is vanishingly
# small for most data.
#
# DDSketch implementations are also available in:
# <a href="https://github.com/DataDog/sketches-go/">Go</a>
# <a href="https://github.com/DataDog/sketches-py/">Python</a>
# <a href="https://github.com/DataDog/sketches-js/">JavaScript</a>

require 'ddsketch/exception'
require 'ddsketch/mapping'
require 'ddsketch/store'

module DDSketch
  # The base implementation of DDSketch with neither mapping nor storage specified.
  class BaseDDSketch
    DEFAULT_REL_ACC = 0.01 # "alpha" in the paper
    DEFAULT_BIN_LIMIT = 2048

    attr_reader :mapping, :store, :negative_store, :zero_count, :min, :max, :sum, :count, :name

    def initialize(
      mapping,
      store,
      negative_store,
      zero_count
    )
      @mapping = mapping
      @store = store
      @negative_store = negative_store
      @zero_count = zero_count

      @relative_accuracy = mapping.relative_accuracy
      @count = @negative_store.count + @zero_count + @store.count
      @min = Float::INFINITY
      @max = -Float::INFINITY
      @sum = 0.0
    end

    def avg
      sum / count
    end

    # Add a value to the sketch.
    def add(val, weight = 1.0)
      raise IllegalArgumentException('weight must be a positive float') if weight <= 0.0

      if val > @mapping.min_possible
        @store.add(@mapping.key(val), weight)
      elsif val < -@mapping.min_possible
        @negative_store.add(@mapping.key(-val), weight)
      else
        @zero_count += weight
      end

      # Keep track of summary stats
      @count += weight
      @sum += val * weight
      @min = val if val < @min
      @max = val if val > @max
    end

    # Return the approximate value at the specified quantile.
    def get_quantile_value(quantile)
      return nil if quantile < 0 || quantile > 1 || @count == 0

      rank = quantile * (@count - 1)
      if rank < @negative_store.count
        reversed_rank = @negative_store.count - rank - 1
        key = @negative_store.key_at_rank(reversed_rank, false)
        quantile_value = -@mapping.value(key)
      elsif rank < @zero_count + @negative_store.count
        return 0
      else
        key = @store.key_at_rank(
          rank - @zero_count - @negative_store.count
        )
        quantile_value = @mapping.value(key)
      end
      quantile_value
    end

    # Merge the given sketch into this one. After this operation, this sketch
    # encodes the values that were added to both this and the input sketch.
    def merge(sketch)
      unless mergeable(sketch)
        raise UnequalSketchParametersException(
          'Cannot merge two DDSketches with different parameters'
        )
      end

      return if sketch.count == 0

      if @count == 0
        _copy(sketch)
        return
      end

      # Merge the stores
      @store.merge(sketch.store)
      @negative_store.merge(sketch.negative_store)
      @zero_count += sketch.zero_count

      # Merge summary stats
      @count += sketch.count
      @sum += sketch.sum
      @min = sketch.min if sketch.min < @min

      @max = sketch.max if sketch.max > @max
    end

    def num_values
      @count
    end

    private

    # Two sketches can be merged only if their gammas are equal.
    def mergeable(other)
      @mapping.gamma == other.mapping.gamma
    end

    # Copy the input sketch into this one
    def _copy(sketch)
      @store.copy(sketch.store)
      @negative_store.copy(sketch.negative_store)
      @zero_count = sketch.zero_count
      @min = sketch.min
      @max = sketch.max
      @count = sketch.count
      @sum = sketch.sum
    end
  end

  # The default implementation of BaseDDSketch, with optimized memory usage at
  # the cost of lower ingestion speed, using an unlimited number of bins. The
  # number of bins will not exceed a reasonable number unless the data is
  # distributed with tails heavier than any subexponential.
  # (cf. http://www.vldb.org/pvldb/vol12/p2195-masson.pdf)
  class DDSketch < BaseDDSketch
    def initialize(relative_accuracy = nil)
      # Make sure the parameters are valid
      relative_accuracy ||= DEFAULT_REL_ACC

      mapping = LogarithmicMapping.new(relative_accuracy)
      store = DenseStore.new
      negative_store = DenseStore.new

      super(
        mapping,
        store,
        negative_store,
        0.0
      )
    end
  end

  # Implementation of BaseDDSketch with optimized memory usage at the cost of
  # lower ingestion speed, using a limited number of bins. When the maximum
  # number of bins is reached, bins with lowest indices are collapsed, which
  # causes the relative accuracy to be lost on the lowest quantiles. For the
  # default bin limit, collapsing is unlikely to occur unless the data is
  # distributed with tails heavier than any subexponential.
  # (cf. http://www.vldb.org/pvldb/vol12/p2195-masson.pdf)
  class LogCollapsingLowestDenseDDSketch < BaseDDSketch
    def initialize(relative_accuracy = nil, bin_limit = nil)
      # Make sure the parameters are valid
      relative_accuracy = DEFAULT_REL_ACC if relative_accuracy.nil?

      bin_limit = DEFAULT_BIN_LIMIT if bin_limit.nil? || bin_limit < 0

      mapping = LogarithmicMapping.new(relative_accuracy)
      store = CollapsingLowestDenseStore.new(bin_limit)
      negative_store = CollapsingLowestDenseStore.new(bin_limit)

      super(
        mapping,
        store,
        negative_store,
        0.0
      )
    end
  end

  # Implementation of BaseDDSketch with optimized memory usage at the cost of
  # lower ingestion speed, using a limited number of bins. When the maximum
  # number of bins is reached, bins with highest indices are collapsed, which
  # causes the relative accuracy to be lost on the highest quantiles. For the
  # default bin limit, collapsing is unlikely to occur unless the data is
  # distributed with tails heavier than any subexponential.
  # (cf. http://www.vldb.org/pvldb/vol12/p2195-masson.pdf)
  class LogCollapsingHighestDenseDDSketch < BaseDDSketch
    def initialize(relative_accuracy = nil, bin_limit = nil)
      # Make sure the parameters are valid
      relative_accuracy = DEFAULT_REL_ACC if relative_accuracy.nil?

      bin_limit = DEFAULT_BIN_LIMIT if bin_limit.nil? || bin_limit < 0

      mapping = LogarithmicMapping.new(relative_accuracy)
      store = CollapsingHighestDenseStore.new(bin_limit)
      negative_store = CollapsingHighestDenseStore.new(bin_limit)
      super(
        mapping,
        store,
        negative_store,
        0.0
      )
    end
  end
end
