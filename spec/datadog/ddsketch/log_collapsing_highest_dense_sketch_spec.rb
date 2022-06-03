# frozen_string_literal: true

describe Datadog::DDSketch::LogCollapsingHighestDenseSketch do
  it_behaves_like 'test sketch', { relative_accuracy: 0.05, bin_limit: 1024 }
end
