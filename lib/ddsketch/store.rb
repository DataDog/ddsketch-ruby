# from __future__ import division

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2020 Datadog, Inc.

# import abc
# import math
# import typing
# import six

module DDSketch
  CHUNK_SIZE = 128

  # class _NegativeIntInfinity(int):
  #   def __ge__(x):
  #     return False
  #
  #   __gt__ = __ge__
  #
  #   def __lt__(x):
  #     return True
  #
  #   __le__ = __lt__
  #
  #
  #   class _PositiveIntInfinity(int):
  #     def __ge__(x):
  #       return True
  #
  #     __gt__ = __ge__
  #
  #     def __lt__(x):
  #       return False
  #
  #     __le__ = __lt__
  #
  #
  #     _neg_infinity = _NegativeIntInfinity()
  #     _pos_infinity = _PositiveIntInfinity()

  #     """
  # Stores map integers to counters. They can be seen as a collection of bins.
  # We start with 128 bins and grow the store in chunks of 128 unless specified
  # otherwise.
  # """
  class Store
    #   """The basic specification of a store
    #
    # Attributes:
    #     count (float): the sum of the counts for the bins
    #     min_key (int): the minimum key bin
    #     max_key (int): the maximum key bin
    # """
    def initialize
      # type: () -> None
      self.count = 0 # type: float
      self.min_key = _pos_infinity # type: int
      self.max_key = _neg_infinity # type: int
    end

    # """Copies the input store into this one."""
    # @abstract
    def copy(store) end

    "" "Return the number of bins." ""
    # @abstract
    def length()
      # type: () -> int
    end

    # """Updates the counter at the specified index key, growing the number of bins if
    #     necessary.
    #     """
    # @abstract
    def add(key, weight = 1.0)
      # type: (int, float) -> None
    end

    # """Return the key for the value at given rank.
    #
    #     E.g., if the non-zero bins are [1, 1] for keys a, b with no offset
    #
    #     if lower = True:
    #          key_at_rank(x) = a for x in [0, 1)
    #          key_at_rank(x) = b for x in [1, 2)
    #
    #     if lower = False:
    #          key_at_rank(x) = a for x in (-1, 0]
    #          key_at_rank(x) = b for x in (0, 1]
    #     """
    # @abstract
    def key_at_rank(rank, lower = true)
      # type: (float, bool) -> int
    end

    # """Merge another store into this one. This should be equivalent as running the
    #     add operations that have been run on the other store on this one.
    #     """
    # @abstract
    def merge(store)
      # type: (Store) -> None
    end
  end

  #A dense store that keeps all the bins between the bin for the min_key and the
  #     bin for the max_key.
  class DenseStore < Store
    # Args:
    #     chunk_size (int, optional): the number of bins to grow by
    #
    # Attributes:
    #     count (int): the sum of the counts for the bins
    #     min_key (int): the minimum key bin
    #     max_key (int): the maximum key bin
    #     offset (int): the difference btw the keys and the index in which they are stored
    #     bins (List[float]): the bins
    def initialize(chunk_size = CHUNK_SIZE)
      # type: (int) -> None
      super

      self.chunk_size = chunk_size # type: int
      self.offset = 0 # type: int
      self.bins = [] # type: List[float]
    end

    def to_s
      # type: () -> str
      repr_str = "{"
      for i, sbin in enumerate(self.bins)
        repr_str += "#{i + offset}: #{sbin}, "
      end
      repr_str += "}}, min_key:#{min_key}, max_key:#{max_key}, offset:#{offset}"
      return repr_str
    end

    def copy(store)
      # type: (DenseStore) -> None
      self.bins = store.bins.dup
      self.count = store.count
      self.min_key = store.min_key
      self.max_key = store.max_key
      self.offset = store.offset
    end

    #        """Return the number of bins."""
    def length()
      # type: () -> int
      return len(self.bins)
    end

    def add(key, weight = 1.0)
      # type: (int, float) -> None
      idx = self._get_index(key)
      self.bins[idx] += weight
      self.count += weight
    end

    #        """Calculate the bin index for the key, extending the range if necessary."""
    def _get_index(key)
      # type: (int) -> int
      if key < self.min_key
        self._extend_range(key)
      elsif key > self.max_key
        self._extend_range(key)
      end

      return key - self.offset
    end

    def _get_new_length(new_min_key, new_max_key)
      # type: (int, int) -> int
      desired_length = new_max_key - new_min_key + 1
      return self.chunk_size * int(math.ceil(desired_length / self.chunk_size))
    end

    #        """Grow the bins as necessary and call _adjust"""
    def _extend_range(key, second_key = None)
      # type: (int, Optional[int]) -> None
      second_key = second_key or key
      new_min_key = min(key, second_key, self.min_key)
      new_max_key = max(key, second_key, self.max_key)

      if self.length() == 0
        # initialize bins
        self.bins = [0.0] * self._get_new_length(new_min_key, new_max_key)
        self.offset = new_min_key
        self._adjust(new_min_key, new_max_key)

      elsif new_min_key >= self.min_key and new_max_key < self.offset + self.length()
        # no need to change the range; just update min/max keys
        self.min_key = new_min_key
        self.max_key = new_max_key

      else
        # grow the bins
        new_length = self._get_new_length(new_min_key, new_max_key)
        if new_length > self.length()
          self.bins.extend([0.0] * (new_length - self.length()))
        end
        self._adjust(new_min_key, new_max_key)
      end
    end

    #    "" "Adjust the bins, the offset, the min_key, and max_key, without resizing the
    #         bins, in order to try making it fit the specified range.
    #         " ""
    def _adjust(new_min_key, new_max_key)
      # type: (int, int) -> None

      self._center_bins(new_min_key, new_max_key)
      self.min_key = new_min_key
      self.max_key = new_max_key
    end

    #"" "Shift the bins; this changes the offset." ""
    def _shift_bins(shift)
      # type: (int) -> None

      if shift > 0
        self.bins = self.bins[0..-shift]
        self.bins[0..0] = [0.0] * shift # TODO: This used to be self.bins[:0]
      else
        self.bins = self.bins[abs(shift)..-1]
        self.bins.extend([0.0] * abs(shift))
      end
      self.offset -= shift
    end

    # """Center the bins; this changes the offset."""
    def _center_bins(new_min_key, new_max_key)
      # type: (int, int) -> None
      middle_key = new_min_key + (new_max_key - new_min_key + 1).floor_div(2)
      self._shift_bins(self.offset + self.length().floor_div(2) - middle_key)
    end

    def key_at_rank(rank, lower = true)
      # type: (float, bool) -> int
      running_ct = 0.0
      for i, bin_ct in enumerate(self.bins)
        running_ct += bin_ct
        if (lower and running_ct > rank) or (not lower and running_ct >= rank + 1)
          return i + self.offset
        end
      end

      return self.max_key
    end

    def merge(store)
      # type: ignore[override]
      # type: (DenseStore) -> None
      return if store.count == 0

      if self.count == 0
        self.copy(store)
        return
      end

      if store.min_key < self.min_key or store.max_key > self.max_key
        self._extend_range(store.min_key, store.max_key)
      end

      for key in range(store.min_key, store.max_key + 1)
        self.bins[key - self.offset] += store.bins[key - store.offset]
      end

      self.count += store.count
    end
  end

  #A dense store that keeps all the bins between the bin for the min_key and the
  #     bin for the max_key, but collapsing the left-most bins if the number of bins
  #     exceeds the bin_limit
  class CollapsingLowestDenseStore < DenseStore
    # Args:
    #     bin_limit (int): the maximum number of bins
    #     chunk_size (int, optional): the number of bins to grow by
    #
    # Attributes:
    #     count (int): the sum of the counts for the bins
    #     min_key (int): the minimum key bin
    #     max_key (int): the maximum key bin
    #     offset (int): the difference btw the keys and the index in which they are stored
    #     bins (List[int]): the bins
    def initialize(bin_limit, chunk_size = CHUNK_SIZE)
      # type: (int, int) -> None
      super
      self.bin_limit = bin_limit
      self.is_collapsed = false
    end

    def copy(store)
      # type: ignore[override]
      # type: (CollapsingLowestDenseStore) -> None
      self.bin_limit = store.bin_limit
      self.is_collapsed = store.is_collapsed
      super().copy(store)
    end

    def _get_new_length(new_min_key, new_max_key)
      # type: (int, int) -> int
      desired_length = new_max_key - new_min_key + 1
      return min(
        self.chunk_size * int(math.ceil(desired_length / self.chunk_size)),
        self.bin_limit,
      )
    end

    # "" "Calculate the bin index for the key, extending the range if necessary." ""
    def _get_index(key)
      # type: (int) -> int

      if key < self.min_key
        if self.is_collapsed
          return 0
        end

        self._extend_range(key)
        if self.is_collapsed
          return 0
        end
      elsif key > self.max_key
        self._extend_range(key)
      end

      return key - self.offset

    end

    # Override. Adjust the bins, the offset, the min_key, and max_key, without
    # resizing the bins, in order to try making it fit the specified
    # range. Collapse to the left if necessary.
    def _adjust(new_min_key, new_max_key)
      # type: (int, int) -> None
      if new_max_key - new_min_key + 1 > self.length()
        # The range of keys is too wide, the lowest bins need to be collapsed.
        new_min_key = new_max_key - self.length() + 1

        if new_min_key >= self.max_key
          # put everything in the first bin
          self.offset = new_min_key
          self.min_key = new_min_key
          self.bins = [0.0] * self.length()
          self.bins[0] = self.count
        else
          shift = self.offset - new_min_key
          if shift < 0
            collapse_start_index = self.min_key - self.offset
            collapse_end_index = new_min_key - self.offset
            collapsed_count = sum(
              self.bins[collapse_start_index: collapse_end_index]
            )
            self.bins[collapse_start_index: collapse_end_index] = [0.0] * (
              new_min_key - self.min_key
            )
            self.bins[collapse_end_index] += collapsed_count
            self.min_key = new_min_key
            # shift the buckets to make room for new_max_key
            self._shift_bins(shift)
          else
            self.min_key = new_min_key
            # shift the buckets to make room for new_min_key
            self._shift_bins(shift)
          end
        end

        self.max_key = new_max_key
        self.is_collapsed = True
      else
        self._center_bins(new_min_key, new_max_key)
        self.min_key = new_min_key
        self.max_key = new_max_key
      end
    end

    def merge(store)
      # type: ignore[override]
      # type: (CollapsingLowestDenseStore) -> None  # type: ignore[override]
      return if store.count == 0

      if self.count == 0
        self.copy(store)
        return
      end

      if store.min_key < self.min_key or store.max_key > self.max_key
        self._extend_range(store.min_key, store.max_key)
      end

      collapse_start_idx = store.min_key - store.offset
      collapse_end_idx = min(self.min_key, store.max_key + 1) - store.offset
      if collapse_end_idx > collapse_start_idx
        collapse_count = sum(store.bins[collapse_start_idx: collapse_end_idx])
        self.bins[0] += collapse_count
      else
        collapse_end_idx = collapse_start_idx
      end

      for key in range(collapse_end_idx + store.offset, store.max_key + 1)
        self.bins[key - self.offset] += store.bins[key - store.offset]
      end

      self.count += store.count
    end
  end

  # A dense store that keeps all the bins between the bin for the min_key and the
  #                                                         bin for the max_key, but collapsing the right-most bins if the number of bins
  #                                                         exceeds the bin_limit
  class CollapsingHighestDenseStore < DenseStore
    # Args:
    #     bin_limit (int): the maximum number of bins
    #     chunk_size (int, optional): the number of bins to grow by
    #
    # Attributes:
    #     count (int): the sum of the counts for the bins
    #     min_key (int): the minimum key bin
    #     max_key (int): the maximum key bin
    #     offset (int): the difference btw the keys and the index in which they are stored
    #     bins (List[int]): the bins
    def initialize(bin_limit, chunk_size = CHUNK_SIZE)
      super
      self.bin_limit = bin_limit
      self.is_collapsed = False
    end

    def copy(store)
      # type: ignore[override]
      # type: (CollapsingHighestDenseStore) -> None
      self.bin_limit = store.bin_limit
      self.is_collapsed = store.is_collapsed
      super().copy(store)
    end

    def _get_new_length(new_min_key, new_max_key)
      # type: (int, int) -> int
      desired_length = new_max_key - new_min_key + 1
      # For some reason mypy can't infer that min(int, int) is an int, so cast it.
      return int(
        min(
          self.chunk_size * int(math.ceil(desired_length / self.chunk_size)),
          self.bin_limit,
        )
      )
    end

    #"""Calculate the bin index for the key, extending the range if necessary"""
    def _get_index(key)
      # type: (int) -> int

      if key > self.max_key
        if self.is_collapsed
          return self.length() - 1
        end

        self._extend_range(key)
        if self.is_collapsed
          return self.length() - 1
        end
      elsif key < self.min_key
        self._extend_range(key)
      end
      return key - self.offset
    end

    #Override. Adjust the bins, the offset, the min_key, and max_key, without
    # resizing the bins, in order to try making it fit the specified
    # range. Collapse to the left if necessary.
    def _adjust(new_min_key, new_max_key)
      # type: (int, int) -> None
      if new_max_key - new_min_key + 1 > self.length()
        # The range of keys is too wide, the lowest bins need to be collapsed.
        new_max_key = new_min_key + self.length() - 1

        if new_max_key <= self.min_key
          # put everything in the last bin
          self.offset = new_min_key
          self.max_key = new_max_key
          self.bins = [0.0] * self.length()
          self.bins[-1] = self.count
        else
          shift = self.offset - new_min_key
          if shift > 0
            collapse_start_index = new_max_key - self.offset + 1
            collapse_end_index = self.max_key - self.offset + 1
            collapsed_count = sum(
              self.bins[collapse_start_index: collapse_end_index]
            )
            self.bins[collapse_start_index: collapse_end_index] = [0.0] * (
              self.max_key - new_max_key
            )
            self.bins[collapse_start_index - 1] += collapsed_count
            self.max_key = new_max_key
            # shift the buckets to make room for new_max_key
            self._shift_bins(shift)
          else
            self.max_key = new_max_key
            # shift the buckets to make room for new_min_key
            self._shift_bins(shift)
          end
        end

        self.min_key = new_min_key
        self.is_collapsed = True
      else
        self._center_bins(new_min_key, new_max_key)
        self.min_key = new_min_key
        self.max_key = new_max_key
      end
    end

    def merge(store)
      # type: ignore[override]
      # type: (CollapsingHighestDenseStore) -> None  # type: ignore[override]
      return if store.count == 0

      if self.count == 0
        self.copy(store)
        return
      end

      if store.min_key < self.min_key or store.max_key > self.max_key
        self._extend_range(store.min_key, store.max_key)
      end

      collapse_end_idx = store.max_key - store.offset + 1
      collapse_start_idx = max(self.max_key + 1, store.min_key) - store.offset
      if collapse_end_idx > collapse_start_idx
        collapse_count = sum(store.bins[collapse_start_idx: collapse_end_idx])
        self.bins[-1] += collapse_count
      else
        collapse_start_idx = collapse_end_idx
      end

      for key in range(store.min_key, collapse_start_idx + store.offset)
        self.bins[key - self.offset] += store.bins[key - store.offset]
      end

      self.count += store.count
    end
  end

end