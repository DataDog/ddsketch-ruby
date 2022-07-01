# frozen_string_literal: true

RSpec.describe Datadog::DDSketch::Store::CollapsingHighestDenseStore do
  extreme_max = 9223372036854775807
  extreme_min = -extreme_max - 1
  bin_limits = [1, 20, 1000]

  it_behaves_like "store protobuf" do
    subject { described_class.new(bin_limit: 10) }
  end

  describe "#add" do
    [
      Array.new(100, 0),
      (0...100).to_a,
      (0...100).to_a.reverse,
      Array.new(10) { |x| 2**x },
      Array.new(16) { |x| 2**x }.reverse,
      (0...9).to_a.map { |i| Array.new(2 * (i + 1)) { i + 1 } }.flatten,
      (0...9).to_a.map { |i| Array.new(2 * (i + 1)) { -(i + 1) } }.flatten,
      [extreme_max],
      [extreme_min],
      [0, extreme_min],
      [0, extreme_max],
      [extreme_min, extreme_max],
      [extreme_max, extreme_min]
    ].each do |values|
      bin_limits.each do |bin_limit|
        context "when adding #{values} for store of bin_limit:#{bin_limit}" do
          it do
            store = described_class.new(bin_limit: bin_limit)

            values.each do |v|
              store.add(v)
            end

            expect(store.bins.inject(:+)).to eq(values.length)

            max_storable_index = values.min + store.bin_limit - 1
            collapsing_values = values.map { |v| [max_storable_index, v].min }

            expect(store).to maintain_weighted_indexed_bins_for(collapsing_values)
          end
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
      [[-8, -8], [-8]],
      [[0], [extreme_min]],
      [[0], [extreme_max]],
      [[extreme_min], [0]],
      [[extreme_max], [0]],
      [[extreme_min], [extreme_min]],
      [[extreme_max], [extreme_max]],
      [[extreme_min], [extreme_max]],
      [[extreme_max], [extreme_min]],
      [[0], [extreme_min, extreme_max]],
      [[extreme_min, extreme_max], [0]]
    ].each do |list_values|
      bin_limits.each do |bin_limit|
        context "when merging #{list_values} for store of bin_limit:#{bin_limit}" do
          it do
            store = described_class.new(bin_limit: bin_limit)

            list_values.each do |values|
              other = described_class.new(bin_limit: bin_limit).tap do |s|
                values.each { |v| s.add(v) }
              end

              store.merge(other)
            end

            flat_values = list_values.flatten

            expect(store.bins.inject(:+)).to eq(flat_values.length)

            max_storable_index = flat_values.min + store.bin_limit - 1
            collapsing_values = flat_values.map { |v| [max_storable_index, v].min }

            expect(store).to maintain_weighted_indexed_bins_for(collapsing_values)
          end
        end
      end
    end
  end
end
