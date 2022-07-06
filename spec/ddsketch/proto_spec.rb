# frozen_string_literal: true

require "ddsketch/proto"

RSpec.describe DDSketch::Proto do
  describe ".serialize_sketch" do
    context "when given a sketch" do
      it do
        sketch = DDSketch::Sketch.new

        protobuf = described_class.serialize_sketch(sketch)

        expect(protobuf).to be_a(DDSketch::Proto::DDSketch)
        expect(protobuf.mapping).to be_a(DDSketch::Proto::IndexMapping)
        expect(protobuf.positiveValues).to be_a(DDSketch::Proto::Store)
        expect(protobuf.negativeValues).to be_a(DDSketch::Proto::Store)
        expect(protobuf.zeroCount).to be_a(Float)
      end
    end
  end

  describe ".serialize_store" do
    context "when given a store" do
      it do
        store = double(bins: [], offset: 0)

        protobuf = described_class.serialize_store(store)

        expect(protobuf).to be_a(DDSketch::Proto::Store)
        expect(protobuf.contiguousBinCounts).to be_a(Google::Protobuf::RepeatedField)
        expect(protobuf.contiguousBinIndexOffset).to be_a(Fixnum)
      end
    end
  end

  describe ".serialize_key_mapping" do
    context "when given key_mapping" do
      it do
        mapping = double(relative_accuracy: 0.01, offset: 1.0, interpolation: nil)

        protobuf = described_class.serialize_key_mapping(mapping)

        expect(protobuf).to be_a DDSketch::Proto::IndexMapping
        expect(protobuf.gamma).to be_a Float
        expect(protobuf.indexOffset).to be_a Float
        expect(protobuf.interpolation).to eq(:NONE)
      end
    end

    context "when given a linear interpolated key_mapping" do
      it do
        mapping = double(relative_accuracy: 0.01, offset: 1.0, interpolation: :linear)

        protobuf = described_class.serialize_key_mapping(mapping)

        expect(protobuf).to be_a DDSketch::Proto::IndexMapping
        expect(protobuf.gamma).to be_a Float
        expect(protobuf.indexOffset).to be_a Float
        expect(protobuf.interpolation).to eq(:LINEAR)
      end
    end

    context "when given a cubically interpolated key_mapping" do
      it do
        mapping = double(relative_accuracy: 0.01, offset: 1.0, interpolation: :cubic)

        protobuf = described_class.serialize_key_mapping(mapping)

        expect(protobuf).to be_a DDSketch::Proto::IndexMapping
        expect(protobuf.gamma).to be_a Float
        expect(protobuf.indexOffset).to be_a Float
        expect(protobuf.interpolation).to eq(:CUBIC)
      end
    end
  end
end
