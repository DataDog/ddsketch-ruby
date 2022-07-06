# frozen_string_literal: true

RSpec.describe DDSketch::Store::CollapsingLowestDenseStore do
  extreme_max = 9223372036854775807
  extreme_min = -extreme_max - 1
  bin_limits = [1, 20, 1000]

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

            values.each do |val|
              store.add(val)
            end

            expect(store.bins.inject(:+)).to eq(values.length)

            min_storable_index = values.max - store.bin_limit + 1
            collapsing_values = values.map { |v| [min_storable_index, v].max }

            expect(store).to maintain_weighted_indexed_bins_for(collapsing_values)
          end
        end
      end
    end
  end

  describe "#merge" do
    merging_values_list = [
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
    ]

    bin_limits.each do |bin_limit|
      merging_values_list.each do |list_values|
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

            min_storable_index = flat_values.max - store.bin_limit + 1
            collapsing_values = flat_values.map { |v| [min_storable_index, v].max }

            expect(store).to maintain_weighted_indexed_bins_for(collapsing_values)
          end
        end
      end
    end
  end

  describe "#copy" do
    it "Test copying empty stores" do
      store = described_class.new(bin_limit: 10)

      store.copy(described_class.new(bin_limit: 10))

      expect(store.count).to eq(0)
    end

    it "Test copying stores" do
      store = described_class.new(bin_limit: 10)
      new_store = described_class.new(bin_limit: 10)

      new_store.add(0)

      store.copy(new_store)

      expect(store.count).to eq(1)
    end
  end
end
