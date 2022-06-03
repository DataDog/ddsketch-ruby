# frozen_string_literal: true

module Datadog
  module DDSketch
    module Store
      # A dense store that keeps all the bins between the bin for the min_key and the
      # bin for the max_key, but collapsing the left-most bins if the number of bins
      # exceeds the bin_limit
      class CollapsingLowestDenseStore < DenseStore
        attr_accessor :bin_limit, :is_collapsed

        def initialize(bin_limit:, chunk_size: CHUNK_SIZE)
          super(chunk_size: chunk_size)

          @bin_limit = bin_limit
          @is_collapsed = false
        end

        def copy(store)
          super(store)

          self.bin_limit = store.bin_limit
          self.is_collapsed = store.is_collapsed
        end

        def get_new_length(new_min_key, new_max_key)
          desired_length = new_max_key - new_min_key + 1

          [
            chunk_size * (desired_length.to_f / chunk_size).ceil,
            bin_limit
          ].min
        end

        # Calculate the bin index for the key, extending the range if necessary.
        def get_index(key)
          if key < min_key
            return 0 if is_collapsed

            extend_range(key)
            return 0 if is_collapsed
          elsif key > max_key
            extend_range(key)
          end

          key - offset
        end

        # Override. Adjust the bins, the offset, the min_key, and max_key, without
        # resizing the bins, in order to try making it fit the specified
        # range. Collapse to the left if necessary.
        def adjust(new_min_key, new_max_key)
          if new_max_key - new_min_key + 1 > length
            # The range of keys is too wide, the lowest bins need to be collapsed.
            new_min_key = new_max_key - length + 1

            if new_min_key >= max_key
              # put everything in the first bin
              self.offset = new_min_key
              self.min_key = new_min_key
              self.bins = [0.0] * length
              bins[0] = count
            else
              shift = offset - new_min_key

              if shift < 0
                collapse_start_index = min_key - offset
                collapse_end_index = new_min_key - offset
                collapsed_count = bins[collapse_start_index...collapse_end_index].inject(:+) || 0

                bins[collapse_start_index...collapse_end_index] = [0.0] * (new_min_key - min_key)
                bins[collapse_end_index] += collapsed_count
              end

              self.min_key = new_min_key
              # shift the buckets to make room for new_min_key
              shift_bins(shift)
            end

            self.max_key = new_max_key
            self.is_collapsed = true
          else
            center_bins(new_min_key, new_max_key)
            self.min_key = new_min_key
            self.max_key = new_max_key
          end
        end

        def merge(store)
          return if store.count == 0

          if count == 0
            copy(store)
            return
          end

          extend_range(store.min_key, store.max_key) if store.min_key < min_key || store.max_key > max_key

          collapse_start_idx = store.min_key - store.offset
          collapse_end_idx = [min_key, store.max_key + 1].min - store.offset

          if collapse_end_idx > collapse_start_idx
            collapse_count = store.bins[collapse_start_idx...collapse_end_idx].inject(:+) || 0
            bins[0] += collapse_count
          else
            collapse_end_idx = collapse_start_idx
          end

          (collapse_end_idx + store.offset).upto(store.max_key).each do |key|
            bins[key - offset] += store.bins[key - store.offset]
          end

          self.count += store.count
        end
      end
    end
  end
end
