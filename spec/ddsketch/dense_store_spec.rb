# frozen_string_literal: true

describe DDSketch::DenseStore do
  def _test_values(store, values)
    counter = values.each_with_object(Hash.new(0)) do |v, hash|
      hash[v] += 1
    end
    expected_total_count = counter.values.inject(:+) || 0

    expect(expected_total_count).to eq(store.bins.inject(:+) || 0)

    if expected_total_count == 0
      expect(store.bins).to all(eq(0))
    else
      store.bins.each_with_index do |bin, index|
        expect(bin).to eq(counter.fetch(index + store.offset, 0)) if bin != 0
      end
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
    (0...9).to_a.map { |i| Array.new(2 * (i + 1)) { -(i + 1) } }.flatten
  ].each do |values|
    it do
      store = described_class.new
      values.each do |v|
        store.add(v)
      end
      _test_values(store, values)
    end
  end

  def _test_merging(list_values)
    store = DDSketch::DenseStore.new

    list_values.each do |values|
      intermediate_store = DDSketch::DenseStore.new

      values.each do |v|
        intermediate_store.add(v)
      end

      store.merge(intermediate_store)
    end

    flat_values = list_values.flatten

    _test_values(store, flat_values)
  end

  [
    [[], []],
    [[-10000], [10000]],
    [[10000], [-10000]],
    [[10000], [-10000], [0]],
    [[10000, 0], [-10000], [0]],
    [[2, 2], [2, 2, 2], [2]],
    [[-8, -8], [-8]]
  ].each do |list_values|
    it do
      _test_merging(list_values)
    end
  end

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
