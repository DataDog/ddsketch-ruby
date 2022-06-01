# frozen_string_literal: true

module DDSketch
  CHUNK_SIZE = 128

  # Stores map integers to counters. They can be seen as a collection of bins.
  # We start with 128 bins and grow the store in chunks of 128 unless specified
  # otherwise.
  class Store
    attr_accessor :count, :min_key, :max_key

    def initialize
      @count = 0
      @min_key = Float::INFINITY
      @max_key = -Float::INFINITY
    end

    def copy(store) end

    def length() end

    def add(key, weight = 1.0) end

    def key_at_rank(rank, lower = true) end

    def merge(store) end
  end

  # A dense store that keeps all the bins between the bin for the min_key and the
  # bin for the max_key.
  class DenseStore < Store
    attr_accessor :chunk_size, :offset, :bins

    def initialize(chunk_size = CHUNK_SIZE)
      super()

      @chunk_size = chunk_size
      @offset = 0
      @bins = []
    end

    # def to_s
    #   repr_str = "{"
    #   for i, sbin in enumerate(self.bins)
    #     repr_str += "#{i + offset}: #{sbin}, "
    #   end
    #   repr_str += "}, min_key:#{min_key}, max_key:#{max_key}, offset:#{offset}"
    #   return repr_str
    # end

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
      idx = _get_index(key)
      bins[idx] += weight
      self.count += weight
    end

    # Calculate the bin index for the key, extending the range if necessary.
    def _get_index(key)
      _extend_range(key) if key < min_key || key > max_key

      key - offset
    end

    def _get_new_length(new_min_key, new_max_key)
      desired_length = new_max_key - new_min_key + 1
      chunk_size * (desired_length.to_f / chunk_size).ceil
    end

    # Grow the bins as necessary and call _adjust
    def _extend_range(key, _second_key = nil) # rubocop:todo Lint/UnderscorePrefixedVariableName
      second_key = _second_key || key
      new_min_key = [key, second_key, min_key].min
      new_max_key = [key, second_key, max_key].max

      if length == 0
        # initialize bins
        self.bins = [0.0] * _get_new_length(new_min_key, new_max_key)
        self.offset = new_min_key
        _adjust(new_min_key, new_max_key)

      elsif new_min_key >= min_key && (new_max_key < (offset + length))
        # no need to change the range; just update min/max keys
        self.min_key = new_min_key
        self.max_key = new_max_key

      else
        # grow the bins
        new_length = _get_new_length(new_min_key, new_max_key)
        bins.push(*([0.0] * (new_length - length))) if new_length > length
        _adjust(new_min_key, new_max_key)
      end
    end

    # Adjust the bins, the offset, the min_key, and max_key, without resizing the
    # bins, in order to try making it fit the specified range.
    def _adjust(new_min_key, new_max_key)
      _center_bins(new_min_key, new_max_key)
      self.min_key = new_min_key
      self.max_key = new_max_key
    end

    # Shift the bins; this changes the offset.
    def _shift_bins(shift)
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
    def _center_bins(new_min_key, new_max_key)
      middle_key = new_min_key + (new_max_key - new_min_key + 1).div(2)
      _shift_bins(self.offset + length.div(2) - middle_key)
    end

    def key_at_rank(rank, lower = true)
      running_ct = 0.0

      bins.each_with_index do |bin_ct, i|
        running_ct += bin_ct

        ## ??
        return i + self.offset if (lower && running_ct > rank) || (!lower && running_ct >= rank + 1)
      end

      max_key
    end

    def merge(store)
      return if store.count == 0

      if self.count == 0
        copy(store)
        return
      end

      _extend_range(store.min_key, store.max_key) if store.min_key < min_key || store.max_key > max_key

      store.min_key.upto(store.max_key).each do |key|
        bins[key - self.offset] += store.bins[key - store.offset]
      end

      self.count += store.count
    end
  end

  # A dense store that keeps all the bins between the bin for the min_key and the
  # bin for the max_key, but collapsing the left-most bins if the number of bins
  # exceeds the bin_limit
  class CollapsingLowestDenseStore < DenseStore
    attr_accessor :bin_limit, :is_collapsed

    def initialize(bin_limit, chunk_size = CHUNK_SIZE)
      super(chunk_size)
      @bin_limit = bin_limit
      @is_collapsed = false
    end

    def copy(store)
      self.bin_limit = store.bin_limit
      self.is_collapsed = store.is_collapsed
      super(store)
    end

    def _get_new_length(new_min_key, new_max_key)
      desired_length = new_max_key - new_min_key + 1

      [
        chunk_size * (desired_length.to_f / chunk_size).ceil,
        bin_limit
      ].min
    end

    # Calculate the bin index for the key, extending the range if necessary.
    def _get_index(key)
      if key < min_key
        return 0 if is_collapsed

        _extend_range(key)
        return 0 if is_collapsed
      elsif key > max_key
        _extend_range(key)
      end

      key - self.offset
    end

    # Override. Adjust the bins, the offset, the min_key, and max_key, without
    # resizing the bins, in order to try making it fit the specified
    # range. Collapse to the left if necessary.
    def _adjust(new_min_key, new_max_key)
      if new_max_key - new_min_key + 1 > length
        # The range of keys is too wide, the lowest bins need to be collapsed.
        new_min_key = new_max_key - length + 1

        if new_min_key >= max_key
          # put everything in the first bin
          self.offset = new_min_key
          self.min_key = new_min_key
          self.bins = [0.0] * length
          bins[0] = self.count
        else
          shift = self.offset - new_min_key

          if shift < 0
            collapse_start_index = min_key - self.offset
            collapse_end_index = new_min_key - self.offset
            collapsed_count = bins[collapse_start_index...collapse_end_index].inject(:+) || 0

            bins[collapse_start_index...collapse_end_index] = [0.0] * (new_min_key - min_key)
            bins[collapse_end_index] += collapsed_count
          end

          self.min_key = new_min_key
          _shift_bins(shift)
        end

        self.max_key = new_max_key
        self.is_collapsed = true
      else
        _center_bins(new_min_key, new_max_key)
        self.min_key = new_min_key
        self.max_key = new_max_key
      end
    end

    def merge(store)
      return if store.count == 0

      if self.count == 0
        copy(store)
        return
      end

      _extend_range(store.min_key, store.max_key) if store.min_key < min_key || store.max_key > max_key

      collapse_start_idx = store.min_key - store.offset
      collapse_end_idx = [min_key, store.max_key + 1].min - store.offset
      if collapse_end_idx > collapse_start_idx
        collapse_count = store.bins[collapse_start_idx...collapse_end_idx].inject(:+) || 0
        bins[0] += collapse_count
      else
        collapse_end_idx = collapse_start_idx
      end

      (collapse_end_idx + store.offset).upto(store.max_key).each do |key|
        bins[key - self.offset] += store.bins[key - store.offset]
      end

      self.count += store.count
    end
  end

  # A dense store that keeps all the bins between the bin for the min_key and the
  # bin for the max_key, but collapsing the right-most bins if the number of bins
  # exceeds the bin_limit
  class CollapsingHighestDenseStore < DenseStore
    attr_accessor :bin_limit, :is_collapsed

    def initialize(bin_limit, chunk_size = CHUNK_SIZE)
      super(chunk_size)
      @bin_limit = bin_limit
      @is_collapsed = false
    end

    def copy(store)
      self.bin_limit = store.bin_limit
      self.is_collapsed = store.is_collapsed
      super(store)
    end

    def _get_new_length(new_min_key, new_max_key)
      desired_length = new_max_key - new_min_key + 1
      # For some reason mypy can't infer that min(int, int) is an int, so cast it.
      [
        chunk_size * (desired_length.to_f / chunk_size).ceil,
        bin_limit
      ].min
    end

    # Calculate the bin index for the key, extending the range if necessary
    def _get_index(key)
      if key > max_key
        return length - 1 if is_collapsed

        _extend_range(key)
        return length - 1 if is_collapsed
      elsif key < min_key
        _extend_range(key)
      end
      key - self.offset
    end

    # Override. Adjust the bins, the offset, the min_key, and max_key, without
    # resizing the bins, in order to try making it fit the specified
    # range. Collapse to the left if necessary.
    def _adjust(new_min_key, new_max_key)
      if new_max_key - new_min_key + 1 > length
        # The range of keys is too wide, the lowest bins need to be collapsed.
        new_max_key = new_min_key + length - 1

        if new_max_key <= min_key
          # put everything in the last bin
          self.offset = new_min_key
          self.max_key = new_max_key
          self.bins = [0.0] * length
          bins[-1] = self.count
        else
          shift = self.offset - new_min_key

          if shift > 0
            collapse_start_index = new_max_key - self.offset + 1
            collapse_end_index = max_key - self.offset + 1
            collapsed_count = bins[collapse_start_index...collapse_end_index].inject(:+) || 0

            bins[collapse_start_index...collapse_end_index] = [0.0] * (max_key - new_max_key)
            bins[collapse_start_index - 1] += collapsed_count
          end

          self.max_key = new_max_key
          _shift_bins(shift)
        end

        self.min_key = new_min_key
        self.is_collapsed = true
      else
        _center_bins(new_min_key, new_max_key)
        self.min_key = new_min_key
        self.max_key = new_max_key
      end
    end

    def merge(store)
      return if store.count == 0

      if self.count == 0
        copy(store)
        return
      end

      _extend_range(store.min_key, store.max_key) if (store.min_key < min_key) || (store.max_key > max_key)

      collapse_end_idx = store.max_key - store.offset + 1
      collapse_start_idx = [max_key + 1, store.min_key].max - store.offset
      if collapse_end_idx > collapse_start_idx
        collapse_count = store.bins[collapse_start_idx...collapse_end_idx].inject(:+) || 0
        bins[-1] += collapse_count
      else
        collapse_start_idx = collapse_end_idx
      end

      (store.min_key).upto(collapse_start_idx + store.offset - 1).each do |key|
        bins[key - self.offset] += store.bins[key - store.offset]
      end

      self.count += store.count
    end
  end
end
