# frozen_string_literal: true

RSpec.describe DDSketch::KeyMapping do
  describe DDSketch::LogarithmicMapping do
    include_context 'mapping tests' do
      let(:mapping) { described_class.new(relative_acccuracy, offset) }
    end
  end

  describe DDSketch::LinearlyInterpolatedMapping do
    include_context 'mapping tests' do
      let(:mapping) { described_class.new(relative_acccuracy, offset) }
    end
  end

  describe DDSketch::CubicallyInterpolatedMapping do
    include_context 'mapping tests' do
      let(:mapping) { described_class.new(relative_acccuracy, offset) }
    end
  end
end
