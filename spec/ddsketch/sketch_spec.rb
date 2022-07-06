# frozen_string_literal: true

RSpec.describe DDSketch::Sketch do
  it_behaves_like "test sketch", {relative_accuracy: 0.05}

  it_behaves_like "sketch protobuf"
end
