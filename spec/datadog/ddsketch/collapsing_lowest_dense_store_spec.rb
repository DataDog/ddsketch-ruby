# frozen_string_literal: true

describe Datadog::DDSketch::CollapsingLowestDenseStore do
  extreme_max = 9223372036854775807
  extreme_min = -extreme_max - 1

  def _test_values(store, values)
    counter = values.each_with_object(Hash.new(0)) do |v, hash|
      hash[v] += 1
    end

    expected_total_count = counter.values.inject(:+) || 0

    expect(expected_total_count).to eq(store.bins.inject(:+) || 0)

    if expected_total_count == 0
      expect(store.bins).to all(eq(0))
    else
      max_index = counter.keys.max

      # Does that make sense finding the max with -inf?
      min_storable_index = [-Float::INFINITY, max_index - store.bin_limit + 1].max

      storable_index_counter = values.map { |v| [min_storable_index, v].max }.each_with_object(Hash.new(0)) do |v, hash|
        hash[v] += 1
      end

      store.bins.each_with_index do |bin, index|
        expect(bin).to eq(storable_index_counter.fetch(index + store.offset)) if bin != 0
      end
    end
  end

  def _test_store(values)
    [1, 20, 1000].each do |bin_limit|
      store = described_class.new(bin_limit: bin_limit)

      values.each do |val|
        store.add(val)
      end

      _test_values(store, values)
    end
  end

  def _test_merging(list_values)
    [1, 20, 1000].each do |bin_limit|
      store = described_class.new(bin_limit: bin_limit)

      list_values.each do |values|
        intermediate_store = described_class.new(bin_limit: bin_limit)

        values.each do |val|
          intermediate_store.add(val)
        end

        store.merge(intermediate_store)
      end

      flat_values = list_values.flatten

      _test_values(store, flat_values)
    end
  end

  [
    [],
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
    it do
      _test_store(values)
    end
  end

  [
    [[], []],
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
    it do
      _test_merging(list_values)
    end
  end

  it 'Test copying empty stores' do
    store = described_class.new(bin_limit: 10)

    store.copy(described_class.new(bin_limit: 10))

    expect(store.count).to eq(0)
  end

  it 'Test copying stores' do
    store = described_class.new(bin_limit: 10)
    new_store = described_class.new(bin_limit: 10)

    new_store.add(0)

    store.copy(new_store)

    expect(store.count).to eq(1)
  end
end
