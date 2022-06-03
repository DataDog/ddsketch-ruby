# frozen_string_literal: true

require 'datadog/ddsketch/version'
require 'datadog/ddsketch/errors'

# sketchs
require 'datadog/ddsketch/base_ddsketch'
require 'datadog/ddsketch/sketch'
require 'datadog/ddsketch/log_collapsing_lowest_dense_sketch'
require 'datadog/ddsketch/log_collapsing_highest_dense_sketch'

# key mappings
require 'datadog/ddsketch/mapping/key_mapping'
require 'datadog/ddsketch/mapping/logarithmic_key_mapping'
require 'datadog/ddsketch/mapping/linear_interpolated_key_mapping'
require 'datadog/ddsketch/mapping/cubically_interpolated_key_mapping'

# dense stores
require 'datadog/ddsketch/store/dense_store'
require 'datadog/ddsketch/store/collapsing_lowest_dense_store'
require 'datadog/ddsketch/store/collapsing_highest_dense_store'

module Datadog
  module DDSketch
  end
end
