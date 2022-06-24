# frozen_string_literal: true

module Datadog
  module DDSketch
    # A quantile sketch with relative-error guarantees. This sketch computes
    # quantile values with an approximation error that is relative to the actual
    # quantile value. It works on both negative and non-negative input values.

    # For instance, using DDSketch with a relative accuracy guarantee set to 1%, if
    # the expected quantile value is 100, the computed quantile value is guaranteed to
    # be between 99 and 101. If the expected quantile value is 1000, the computed
    # quantile value is guaranteed to be between 990 and 1010.

    # DDSketch works by mapping floating-point input values to bins and counting the
    # number of values for each bin. The underlying structure that keeps track of bin
    # counts is store.

    # The memory size of the sketch depends on the range that is covered by the input
    # values: the larger that range, the more bins are needed to keep track of the
    # input values. As a rough estimate, if working on durations with a relative
    # accuracy of 2%, about 2kB (275 bins) are needed to cover values between 1
    # millisecond and 1 minute, and about 6kB (802 bins) to cover values between 1
    # nanosecond and 1 day.

    # The size of the sketch can be have a fail-safe upper-bound by using collapsing
    # stores. As shown in
    # <a href="http://www.vldb.org/pvldb/vol12/p2195-masson.pdf">the DDSketch paper</a>
    # the likelihood of a store collapsing when using the default bound is vanishingly
    # small for most data.

    # DDSketch implementations are also available in:
    # <a href="https://github.com/DataDog/sketches-go/">Go</a>
    # <a href="https://github.com/DataDog/sketches-py/">Python</a>
    # <a href="https://github.com/DataDog/sketches-js/">JavaScript</a>

    class BaseDDSketch
      DEFAULT_REL_ACC = 0.01 # "alpha" in the paper
      DEFAULT_BIN_LIMIT = 2048

      attr_reader :mapping, :store, :negative_store, :zero_count, :min, :max, :sum, :count, :name

      def initialize(
        mapping:,
        store:,
        negative_store:,
        zero_count: 0.0
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
        raise ArgumentError, 'weight must be positive' if weight <= 0.0

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
        unless mergeable?(sketch)
          raise InvalidSketchMergeError, 'Cannot merge two sketches with different relative accuracy'
        end

        return if sketch.count == 0

        if @count == 0
          copy(sketch)
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

      def to_proto
        ::DDSketch.new(
          mapping: mapping.to_proto,
          positiveValues: @store.to_proto,
          negativeValues: @negative_store.to_proto,
          zeroCount: @zero_count
        )
      end

      private

      # Two sketches can be merged only if their gammas are equal.
      def mergeable?(other)
        @mapping.gamma == other.mapping.gamma
      end

      # Copy the input sketch into this one
      def copy(sketch)
        @store.copy(sketch.store)
        @negative_store.copy(sketch.negative_store)
        @zero_count = sketch.zero_count
        @min = sketch.min
        @max = sketch.max
        @count = sketch.count
        @sum = sketch.sum
      end
    end
  end
end
