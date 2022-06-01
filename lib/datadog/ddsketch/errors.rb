# frozen_string_literal: true

module Datadog
  module DDSketch
    class BaseError < ::StandardError
    end

    class InvalidSketchMergeError < BaseError
    end

    class InvalidArgumentException < BaseError
    end
  end
end
