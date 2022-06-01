# frozen_string_literal: true

shared_examples 'test sketch' do |args|
  def test_quantiles
    [0, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999, 1].freeze
  end

  def test_sizes
    [3, 5, 10, 100, 1000].freeze
  end

  def _evaluate_sketch_accuracy(sketch, data, eps, summary_stats = true)
    size = data.size

    test_quantiles.each do |quantile|
      sketch_q = sketch.get_quantile_value(quantile)
      data_q = data.quantile(quantile)
      err = (sketch_q - data_q).abs
      expect(err - eps * data_q.abs).to be <= 1e-15
    end

    expect(sketch.num_values).to eq(size)

    if summary_stats
      expect(sketch.sum).to be_within(1e-3).of(data.sum)
      expect(sketch.avg).to be_within(1e-3).of(data.avg)
    end
  end

  it 'test_distributions' do
    datasets = [
      UniformForward,
      UniformBackward,
      UniformZoomIn,
      UniformZoomOut,
      UniformSqrt,
      Constant,
      NegativeUniformBackward,
      NegativeUniformForward,
      NumberLineBackward,
      NumberLineForward
    ]
    datasets.each do |dataset_klass|
      test_sizes.each do |size|
        dataset = dataset_klass.new(size)
        sketch = described_class.new(**args)

        dataset.data.each do |value|
          sketch.add(value)
        end

        _evaluate_sketch_accuracy(sketch, dataset, args[:relative_accuracy])
      end
    end

    [Exponential, Lognormal, Bimodal, Mixed, Trimodal].each do |dataset_klass|
      dataset = dataset_klass.new
      sketch = described_class.new(**args)

      dataset.data.each do |value|
        sketch.add(value)
      end

      _evaluate_sketch_accuracy(sketch, dataset, args[:relative_accuracy])
    end
  end

  it 'test_add_multiple' do
    sketch = described_class.new(**args)

    dataset = Integers.new(1000)
    counter = dataset.data.each_with_object(Hash.new(0)) do |v, hash|
      hash[v] += 1
    end

    counter.each do |value, count|
      sketch.add(value, count)
    end

    _evaluate_sketch_accuracy(sketch, dataset, args[:relative_accuracy])
  end

  it 'test_add_decimal' do
    sketch = described_class.new(**args)

    (0...100).each do |value|
      sketch.add(value, 1.1)
    end

    sketch.add(100, 110.0)

    data_median = 99
    sketch_median = sketch.get_quantile_value(0.5)
    err = (sketch_median - data_median).abs

    expect(err - args[:relative_accuracy] * data_median.abs).to be <= 1e-15

    expect(sketch.count).to be_within(1e-3).of(110 * 2)
    expect(sketch.sum).to be_within(1e-3).of(5445 + 11000)
    expect(sketch.avg).to be_within(1e-3).of(74.75)
  end

  it 'test_merge_equal' do
    parameters = [[35, 1], [1, 3], [15, 2], [40, 0.5]]
    # for size in test_sizes:
    test_sizes.each do |size|
      dataset = EmptyDataset.new(0)
      target_sketch = described_class.new(**args)

      parameters.each do |params|
        generator = Normal.new(size, params[0], params[1])
        sketch = described_class.new(**args)

        generator.data.each do |value|
          sketch.add(value)
          dataset.add(value)
        end

        target_sketch.merge(sketch)

        _evaluate_sketch_accuracy(target_sketch, dataset, args[:relative_accuracy])
      end
    end
  end

  it 'test_merge_unequal' do
    dataset = Lognormal.new
    sketch1 = described_class.new(**args)
    sketch2 = described_class.new(**args)

    rng = Random.new
    dataset.data.each do |value|
      if rng.rand > 0.7
        sketch1.add(value)
      else
        sketch2.add(value)
      end
    end

    sketch1.merge(sketch2)

    _evaluate_sketch_accuracy(sketch1, dataset, args[:relative_accuracy])
  end

  it 'test_merge_mixed' do
    merged_dataset = EmptyDataset.new(0)
    merged_sketch = described_class.new(**args)

    [
      Normal.new(100),
      Exponential.new,
      Laplace.new,
      Bimodal.new
    ].each do |dataset|
      sketch = described_class.new(**args)

      dataset.data.each do |value|
        sketch.add(value)
        merged_dataset.add(value)
      end

      merged_sketch.merge(sketch)
    end

    _evaluate_sketch_accuracy(merged_sketch, merged_dataset, args[:relative_accuracy])
  end

  it 'test_consistent_merge' do
    sketch1 = described_class.new(**args)
    sketch2 = described_class.new(**args)

    rng = Distribution::Normal.rng(37.4, 1.0)

    Array.new(100) { rng.call }.each do |value|
      sketch1.add(value)
    end

    sketch1.merge(sketch2)
    # sketch2 is still empty
    expect(sketch2.num_values).to eq(0)

    Array.new(50) { rng.call }.each do |value|
      sketch2.add(value)
    end

    sketch2_quantile_values = test_quantiles.map { |q| sketch2.get_quantile_value(q) }
    sketch2_values = [sketch2.sum, sketch2.avg, sketch2.num_values]

    sketch1.merge(sketch2)

    #### missing spec

    Array.new(100) { rng.call }.each do |value|
      sketch1.add(value)
    end

    # changes to sketch1 does not affect sketch2 after merge
    test_quantiles.each_with_index do |q, index|
      expect(sketch2.get_quantile_value(q)).to be_within(1e-3).of(sketch2_quantile_values[index])
    end
    expect(sketch2.sum).to be_within(1e-3).of(sketch2_values[0])
    expect(sketch2.avg).to be_within(1e-3).of(sketch2_values[1])
    expect(sketch2.num_values).to be_within(1e-3).of(sketch2_values[2])

    sketch3 = described_class.new(**args)
    sketch3.merge(sketch2)

    # merging to an empty sketch does not change sketch2
    test_quantiles.each_with_index do |q, index|
      expect(sketch2.get_quantile_value(q)).to be_within(1e-3).of(sketch2_quantile_values[index])
    end
    expect(sketch2.sum).to be_within(1e-3).of(sketch2_values[0])
    expect(sketch2.avg).to be_within(1e-3).of(sketch2_values[1])
    expect(sketch2.num_values).to be_within(1e-3).of(sketch2_values[2])
  end
end
