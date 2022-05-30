# frozen_string_literal: true

module DDSketch
  class IllegalArgumentException < StandardError
  end

  # thrown when trying to merge two sketches with different relative_accuracy
  # parameters
  class UnequalSketchParametersException < StandardError
  end
end
