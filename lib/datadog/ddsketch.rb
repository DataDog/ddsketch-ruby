# frozen_string_literal: true

# version
require 'datadog/ddsketch/version'

# sketchs
require 'datadog/ddsketch/base_ddsketch'
require 'datadog/ddsketch/sketch'
require 'datadog/ddsketch/log_collapsing_lowest_dense_sketch'
require 'datadog/ddsketch/log_collapsing_highest_dense_sketch'

# key mappings
require 'datadog/ddsketch/key_mapping'
require 'datadog/ddsketch/logarithmic_key_mapping'
require 'datadog/ddsketch/linear_interpolated_key_mapping'
require 'datadog/ddsketch/cubically_interpolated_key_mapping'

# dense stores
require 'datadog/ddsketch/dense_store'
require 'datadog/ddsketch/collapsing_lowest_dense_store'
require 'datadog/ddsketch/collapsing_highest_dense_store'

module Datadog
  module DDSketch
  end
end
