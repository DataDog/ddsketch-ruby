# frozen_string_literal: true

module Datadog
  module DDSketch
    # The default implementation of BaseDDSketch, with optimized memory usage at
    # the cost of lower ingestion speed, using an unlimited number of bins. The
    # number of bins will not exceed a reasonable number unless the data is
    # distributed with tails heavier than any subexponential.
    # (cf. http://www.vldb.org/pvldb/vol12/p2195-masson.pdf)
    class Sketch < BaseDDSketch
      def initialize(relative_accuracy: DEFAULT_REL_ACC)
        super(
          mapping: Mapping::LogarithmicKeyMapping.new(relative_accuracy: relative_accuracy),
          store: Store::DenseStore.new,
          negative_store: Store::DenseStore.new
        )
      end
    end
  end
end
