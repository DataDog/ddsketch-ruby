# frozen_string_literal: true

require "ddsketch/version"
require "ddsketch/errors"

# sketchs
require "ddsketch/base_sketch"
require "ddsketch/sketch"
require "ddsketch/log_collapsing_lowest_dense_sketch"
require "ddsketch/log_collapsing_highest_dense_sketch"

# key mappings
require "ddsketch/mapping/key_mapping"
require "ddsketch/mapping/logarithmic_key_mapping"
require "ddsketch/mapping/linear_interpolated_key_mapping"
require "ddsketch/mapping/cubically_interpolated_key_mapping"

# dense stores
require "ddsketch/store/dense_store"
require "ddsketch/store/collapsing_lowest_dense_store"
require "ddsketch/store/collapsing_highest_dense_store"

# Namespace for DDSketch library
module DDSketch
end
