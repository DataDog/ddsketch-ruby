# frozen_string_literal: true

RSpec.describe Datadog::DDSketch::Store::DenseStore do
  it_behaves_like "store protobuf"

  describe "#add" do
    [
      Array.new(100, 0),
      (0...100).to_a,
      (0...100).to_a.reverse,
      Array.new(10) { |x| 2**x },
      Array.new(16) { |x| 2**x }.reverse,
      (0...9).to_a.map { |i| Array.new(2 * (i + 1)) { i + 1 } }.flatten,
      (0...9).to_a.map { |i| Array.new(2 * (i + 1)) { -(i + 1) } }.flatten
    ].each do |values|
      context "when given #{values}" do
        it do
          store = described_class.new

          values.each do |v|
            store.add(v)
          end

          expect(store.bins.inject(:+)).to eq(values.length)
          expect(store).to maintain_weighted_indexed_bins_for(values)
        end
      end
    end
  end

  describe "#merge" do
    [
      [[-10000], [10000]],
      [[10000], [-10000]],
      [[10000], [-10000], [0]],
      [[10000, 0], [-10000], [0]],
      [[2, 2], [2, 2, 2], [2]],
      [[-8, -8], [-8]]
    ].each do |list_values|
      context "when given #{list_values}" do
        it do
          store = described_class.new

          list_values.each do |values|
            other = described_class.new.tap do |s|
              values.each { |v| s.add(v) }
            end

            store.merge(other)
          end

          flat_values = list_values.flatten

          expect(store.bins.inject(:+)).to eq(flat_values.length)
          expect(store).to maintain_weighted_indexed_bins_for(flat_values)
        end
      end
    end
  end

  describe "#key_at_rank" do
    it do
      store = described_class.new

      store.add(4)
      store.add(10)
      store.add(100)

      expect(store.key_at_rank(0)).to eq(4)
      expect(store.key_at_rank(1)).to eq(10)
      expect(store.key_at_rank(2)).to eq(100)
      expect(store.key_at_rank(0, false)).to eq(4)
      expect(store.key_at_rank(1, false)).to eq(10)
      expect(store.key_at_rank(2, false)).to eq(100)
      expect(store.key_at_rank(0.5)).to eq(4)
      expect(store.key_at_rank(1.5)).to eq(10)
      expect(store.key_at_rank(2.5)).to eq(100)
      expect(store.key_at_rank(-0.5, false)).to eq(4)
      expect(store.key_at_rank(0.5, false)).to eq(10)
      expect(store.key_at_rank(1.5, false)).to eq(100)
    end
  end
end
