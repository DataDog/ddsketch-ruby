describe Datadog::DDSketch::Mapping::LogarithmicKeyMapping do
  it_behaves_like 'mapping protobuf', :NONE do
    subject { described_class.new(relative_accuracy: 0.01) }
  end

  include_context 'mapping tests' do
    let(:mapping) { described_class.new(relative_accuracy: relative_accuracy, offset: offset) }
  end
end
