# frozen_string_literal: true

module DDSketch
  # Implementation of BaseSketch with optimized memory usage at the cost of
  # lower ingestion speed, using a limited number of bins. When the maximum
  # number of bins is reached, bins with lowest indices are collapsed, which
  # causes the relative accuracy to be lost on the lowest quantiles. For the
  # default bin limit, collapsing is unlikely to occur unless the data is
  # distributed with tails heavier than any subexponential.
  class LogCollapsingLowestDenseSketch < BaseSketch
    # @param relative_accuracy (see Sketch#initialize)
    # @param [Integer] bin_limit the maximum number of bins
    def initialize(relative_accuracy: DEFAULT_REL_ACC, bin_limit: DEFAULT_BIN_LIMIT)
      super(
        mapping: Mapping::LogarithmicKeyMapping.new(relative_accuracy: relative_accuracy),
        store: Store::CollapsingLowestDenseStore.new(bin_limit: bin_limit),
        negative_store: Store::CollapsingLowestDenseStore.new(bin_limit: bin_limit)
      )
    end
  end
end
