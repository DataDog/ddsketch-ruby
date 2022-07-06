# frozen_string_literal: true

RSpec.describe DDSketch::LogCollapsingLowestDenseSketch do
  it_behaves_like "test sketch", {relative_accuracy: 0.05, bin_limit: 1024}
end
