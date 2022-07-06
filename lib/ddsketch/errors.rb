# frozen_string_literal: true

module DDSketch
  class BaseError < ::StandardError
  end

  # Error when merging two incompatible sketches
  class InvalidSketchMergeError < BaseError
  end
end
