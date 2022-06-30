# frozen_string_literal: true

shared_examples 'mapping protobuf' do |interpolation|
  describe '#to_proto' do
    it 'returns a IndexMapping protobuf' do
      protobuf = subject.to_proto

      expect(protobuf).to be_a Datadog::DDSketch::Proto::IndexMapping
      expect(protobuf.gamma).to be_a Float
      expect(protobuf.indexOffset).to be_a Float
      expect(protobuf.interpolation).to eq(interpolation)
    end
  end
end
