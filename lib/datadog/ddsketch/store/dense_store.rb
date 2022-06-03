# frozen_string_literal: true

module Datadog
  module DDSketch
    module Store
      # Stores map integers to counters. They can be seen as a collection of bins.
      # We start with 128 bins and grow the store in chunks of 128 unless specified
      # otherwise.

      # A dense store that keeps all the bins between the bin for the min_key and the
      # bin for the max_key.
      class DenseStore
        CHUNK_SIZE = 128

        attr_accessor :count, :min_key, :max_key, :chunk_size, :offset, :bins

        def initialize(chunk_size: CHUNK_SIZE)
          @count = 0
          @min_key = Float::INFINITY
          @max_key = -Float::INFINITY

          @chunk_size = chunk_size
          @offset = 0
          @bins = []
        end

        def copy(store)
          self.bins = store.bins.dup
          self.count = store.count
          self.min_key = store.min_key
          self.max_key = store.max_key
          self.offset = store.offset
        end

        def length
          bins.length
        end

        def add(key, weight = 1.0)
          idx = get_index(key)
          bins[idx] += weight
          self.count += weight
        end

        # Calculate the bin index for the key, extending the range if necessary.
        def get_index(key)
          extend_range(key) if key < min_key || key > max_key

          key - offset
        end

        def get_new_length(new_min_key, new_max_key)
          desired_length = new_max_key - new_min_key + 1

          chunk_size * (desired_length.to_f / chunk_size).ceil
        end

        # Grow the bins as necessary and call adjust
        def extend_range(key, _second_key = nil) # rubocop:todo Lint/UnderscorePrefixedVariableName
          second_key = _second_key || key
          new_min_key = [key, second_key, min_key].min
          new_max_key = [key, second_key, max_key].max

          if length == 0
            # initialize bins
            self.bins = [0.0] * get_new_length(new_min_key, new_max_key)
            self.offset = new_min_key
            adjust(new_min_key, new_max_key)

          elsif new_min_key >= min_key && (new_max_key < (offset + length))
            # no need to change the range; just update min/max keys
            self.min_key = new_min_key
            self.max_key = new_max_key

          else
            # grow the bins
            new_length = get_new_length(new_min_key, new_max_key)
            bins.push(*([0.0] * (new_length - length))) if new_length > length
            adjust(new_min_key, new_max_key)
          end
        end

        # Adjust the bins, the offset, the min_key, and max_key, without resizing the
        # bins, in order to try making it fit the specified range.
        def adjust(new_min_key, new_max_key)
          center_bins(new_min_key, new_max_key)

          self.min_key = new_min_key
          self.max_key = new_max_key
        end

        # Shift the bins; this changes the offset.
        def shift_bins(shift)
          if shift > 0
            self.bins = bins[0...-shift]
            bins.unshift(*([0.0] * shift))
          else
            self.bins = bins[(shift.abs)..-1]
            bins.push(*([0.0] * shift.abs))
          end
          self.offset -= shift
        end

        # Center the bins; this changes the offset.
        def center_bins(new_min_key, new_max_key)
          middle_key = new_min_key + (new_max_key - new_min_key + 1).div(2)

          shift_bins(offset + length.div(2) - middle_key)
        end

        def key_at_rank(rank, lower = true)
          running_ct = 0.0

          bins.each_with_index do |bin_ct, i|
            running_ct += bin_ct

            ## ??
            return i + offset if (lower && running_ct > rank) || (!lower && running_ct >= rank + 1)
          end

          max_key
        end

        def merge(store)
          return if store.count == 0

          if count == 0
            copy(store)
            return
          end

          extend_range(store.min_key, store.max_key) if store.min_key < min_key || store.max_key > max_key

          store.min_key.upto(store.max_key).each do |key|
            bins[key - offset] += store.bins[key - store.offset]
          end

          self.count += store.count
        end
      end
    end
  end
end
