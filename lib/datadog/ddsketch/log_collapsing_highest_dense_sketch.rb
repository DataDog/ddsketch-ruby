# frozen_string_literal: true

module Datadog
  module DDSketch
    # Implementation of BaseSketch with optimized memory usage at the cost of
    # lower ingestion speed, using a limited number of bins. When the maximum
    # number of bins is reached, bins with highest indices are collapsed, which
    # causes the relative accuracy to be lost on the highest quantiles. For the
    # default bin limit, collapsing is unlikely to occur unless the data is
    # distributed with tails heavier than any subexponential.
    # (cf. http://www.vldb.org/pvldb/vol12/p2195-masson.pdf)
    class LogCollapsingHighestDenseSketch < BaseSketch
      def initialize(
        relative_accuracy: DEFAULT_REL_ACC,
        bin_limit: DEFAULT_BIN_LIMIT
      )
        super(
          mapping: Mapping::LogarithmicKeyMapping.new(relative_accuracy: relative_accuracy),
          store: Store::CollapsingHighestDenseStore.new(bin_limit: bin_limit),
          negative_store: Store::CollapsingHighestDenseStore.new(bin_limit: bin_limit)
        )
      end
    end
  end
end
