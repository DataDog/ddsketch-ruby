# frozen_string_literal: true

module DDSketch
  module Store
    # A dense store that keeps all the bins between the bin for the min_key and the
    # bin for the max_key, but collapsing the right-most bins if the number of bins
    # exceeds the bin_limit
    class CollapsingHighestDenseStore < DenseStore
      # @return [Integer] the maximum number of bins
      attr_reader :bin_limit

      # @return [Boolean] whether the store has been collapsed
      attr_reader :is_collapsed

      # @param [Integer] bin_limit the maximum number of bins
      # @param [Integer] chunk_size the number of bins to grow by
      def initialize(bin_limit:, chunk_size: CHUNK_SIZE)
        super(chunk_size: chunk_size)

        @bin_limit = bin_limit
        @is_collapsed = false
      end

      # Copies the input store into the current store
      #
      # @param [Store::CollapsingHighestDenseStore] store the store to be copied
      #
      # @return [nil]
      def copy(store)
        super(store)

        self.bin_limit = store.bin_limit
        self.is_collapsed = store.is_collapsed

        nil
      end

      # Merge another store into the current store.
      #   collapsing the right-most bins if the number of bins
      #   exceeds the bin_limit
      #
      # @param [Store::CollapsingHighestDenseStore] store
      #   the store to be merged
      #
      # @return [nil]
      def merge(store)
        return if store.count == 0

        if count == 0
          copy(store)
          return
        end

        extend_range(store.min_key, store.max_key) if (store.min_key < min_key) || (store.max_key > max_key)

        collapse_end_idx = store.max_key - store.offset + 1
        collapse_start_idx = [max_key + 1, store.min_key].max - store.offset
        if collapse_end_idx > collapse_start_idx
          collapse_count = store.bins[collapse_start_idx...collapse_end_idx].inject(:+) || 0
          bins[-1] += collapse_count
        else
          collapse_start_idx = collapse_end_idx
        end

        (store.min_key).upto(collapse_start_idx + store.offset - 1).each do |key|
          bins[key - offset] += store.bins[key - store.offset]
        end

        self.count += store.count

        nil
      end

      protected

      attr_writer :bin_limit, :is_collapsed

      private

      def get_new_length(new_min_key, new_max_key)
        desired_length = new_max_key - new_min_key + 1
        # For some reason mypy can't infer that min(int, int) is an int, so cast it.
        [
          chunk_size * (desired_length.to_f / chunk_size).ceil,
          bin_limit
        ].min
      end

      # Calculate the bin index for the key, extending the range if necessary
      def get_index(key)
        if key > max_key
          return length - 1 if is_collapsed

          extend_range(key)
          return length - 1 if is_collapsed
        elsif key < min_key
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
          new_max_key = new_min_key + length - 1

          if new_max_key <= min_key
            # put everything in the last bin
            self.offset = new_min_key
            self.max_key = new_max_key
            self.bins = [0.0] * length
            bins[-1] = count
          else
            shift = offset - new_min_key

            if shift > 0
              collapse_start_index = new_max_key - offset + 1
              collapse_end_index = max_key - offset + 1
              collapsed_count = bins[collapse_start_index...collapse_end_index].inject(:+) || 0

              bins[collapse_start_index...collapse_end_index] = [0.0] * (max_key - new_max_key)
              bins[collapse_start_index - 1] += collapsed_count
            end

            self.max_key = new_max_key
            # shift the buckets to make room for new_max_key
            shift_bins(shift)
          end

          self.min_key = new_min_key
          self.is_collapsed = true
        else
          center_bins(new_min_key, new_max_key)
          self.min_key = new_min_key
          self.max_key = new_max_key
        end
      end
    end
  end
end
