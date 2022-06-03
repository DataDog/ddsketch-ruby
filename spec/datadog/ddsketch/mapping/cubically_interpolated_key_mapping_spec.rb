describe Datadog::DDSketch::Mapping::CubicallyInterpolatedKeyMapping do
  before { skip 'Skipping `Math.ldexp` is inconsistent between JRuby & MRI' if RUBY_PLATFORM == 'java' }

  include_context 'mapping tests' do
    let(:mapping) { described_class.new(relative_accuracy: relative_accuracy, offset: offset) }
  end
end
