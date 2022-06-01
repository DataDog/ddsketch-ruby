describe Datadog::DDSketch::LinearlyInterpolatedKeyMapping do
  include_context 'mapping tests' do
    let(:mapping) { described_class.new(relative_accuracy: relative_accuracy, offset: offset) }
  end
end
