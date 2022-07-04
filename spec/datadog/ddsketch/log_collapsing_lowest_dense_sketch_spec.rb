# frozen_string_literal: true

RSpec.describe Datadog::DDSketch::LogCollapsingLowestDenseSketch do
  it_behaves_like "test sketch", {relative_accuracy: 0.05, bin_limit: 1024}

  it_behaves_like "sketch protobuf"
end
