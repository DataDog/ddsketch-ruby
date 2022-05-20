describe DDSketch::CollapsingHighestDenseStore do
  EXTREME_MAX = 9223372036854775807
  EXTREME_MIN = -EXTREME_MAX-1

  def _test_values(store, values)
    counter = values.tally

    expected_total_count = counter.values.sum

    expect(expected_total_count).to eq(store.bins.sum)

    if expected_total_count == 0
      store.bins.each do |b|
        expect(b).to eq(0)
      end
    else
      # Does at least one non-zero assertion make sense?
      min_index = counter.keys.min

      # Does that make sense finding the max with -inf?
      max_storable_index = [Float::INFINITY, min_index + store.bin_limit - 1].min

      counter = values.map { |v| [max_storable_index, v].min }.tally

      store.bins.each_with_index do |bin, index|
        if bin != 0
          expect(bin).to eq(counter.fetch(index + store.offset))
        end
      end
    end
  end

  def _test_store(values)
    [20].each do |bin_limit|
      store = described_class.new(bin_limit)

      values.each do |val|
        store.add(val)
      end

      _test_values(store, values)
    end
  end

  def _test_merging(list_values)
    [1, 20, 1000].each do |bin_limit|
      store = described_class.new(bin_limit)

      list_values.each do |values|
        intermediate_store = described_class.new(bin_limit)

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
    (0...9).to_a.map{|i| Array.new(2*(i+1)) {i+1}}.flatten,
    (0...9).to_a.map{|i| Array.new(2*(i+1)) {-(i+1)}}.flatten,
    [EXTREME_MAX],
    [EXTREME_MIN],
    [0, EXTREME_MIN],
    [0, EXTREME_MAX],
    [EXTREME_MIN, EXTREME_MAX],
    [EXTREME_MAX, EXTREME_MIN]
  ].each do |values|
    it do
      _test_store(values)
    end
  end

  [
    [[],[]],
    [[-10000], [10000]],
    [[10000], [-10000]],
    [[10000], [-10000], [0]],
    [[10000, 0], [-10000], [0]],
    [[2, 2], [2, 2, 2], [2]],
    [[-8, -8], [-8]],
    [[0], [EXTREME_MIN]],
    [[0], [EXTREME_MAX]],
    [[EXTREME_MIN], [0]],
    [[EXTREME_MAX], [0]],
    [[EXTREME_MIN], [EXTREME_MIN]],
    [[EXTREME_MAX], [EXTREME_MAX]],
    [[EXTREME_MIN], [EXTREME_MAX]],
    [[EXTREME_MAX], [EXTREME_MIN]],
    [[0], [EXTREME_MIN, EXTREME_MAX]],
    [[EXTREME_MIN, EXTREME_MAX], [0]]
  ].each do |list_values|
    it do
      _test_merging(list_values)
    end
  end
end
