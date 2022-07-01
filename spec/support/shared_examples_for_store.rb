# frozen_string_literal: true

shared_examples "store protobuf" do
  describe "#to_proto" do
    it "returns a Store protobuf" do
      protobuf = subject.to_proto

      expect(protobuf).to be_a(Datadog::DDSketch::Proto::Store)
      expect(protobuf.contiguousBinCounts).to be_a(Google::Protobuf::RepeatedField)
      expect(protobuf.contiguousBinIndexOffset).to be_a(Integer)
    end
  end
end
