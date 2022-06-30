# frozen_string_literal: true

shared_examples "test sketch" do |args|
  test_quantiles = [0, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999, 1].freeze
  test_sizes = [3, 5, 10, 100, 1000].freeze

  describe "#add" do
    [
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
    ].each do |dataset_klass|
      test_sizes.each do |size|
        context "when given a #{dataset_klass} of size: #{size}" do
          it do
            distribution = dataset_klass.new(size)
            sketch = described_class.new(**args)

            distribution.data.each do |value|
              sketch.add(value)
            end

            expect(sketch.num_values).to eq(distribution.size)
            expect(sketch.sum).to be_within(1e-3).of(distribution.sum)
            expect(sketch.avg).to be_within(1e-3).of(distribution.avg)

            test_quantiles.each do |q|
              expect(sketch).to guarantee_accuracy(distribution, args[:relative_accuracy]).at_quantile(q)
            end
          end
        end
      end
    end

    [Exponential, Lognormal, Bimodal, Mixed, Trimodal].each do |dataset_klass|
      context "when given #{dataset_klass}" do
        it do
          distribution = dataset_klass.new
          sketch = described_class.new(**args)

          distribution.data.each do |value|
            sketch.add(value)
          end

          expect(sketch.num_values).to eq(distribution.size)
          expect(sketch.sum).to be_within(1e-3).of(distribution.sum)
          expect(sketch.avg).to be_within(1e-3).of(distribution.avg)

          test_quantiles.each do |q|
            expect(sketch).to guarantee_accuracy(distribution, args[:relative_accuracy]).at_quantile(q)
          end
        end
      end
    end

    context "when #add with weight" do
      it do
        sketch = described_class.new(**args)

        distribution = Integers.new(1000)
        counter = distribution.data.each_with_object(Hash.new(0)) do |v, hash|
          hash[v] += 1
        end

        counter.each do |value, count|
          sketch.add(value, count)
        end

        expect(sketch.num_values).to eq(distribution.size)
        expect(sketch.sum).to be_within(1e-3).of(distribution.sum)
        expect(sketch.avg).to be_within(1e-3).of(distribution.avg)

        test_quantiles.each do |q|
          expect(sketch).to guarantee_accuracy(distribution, args[:relative_accuracy]).at_quantile(q)
        end
      end

      it do
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

      context "when given weight is smaller or equal to zero" do
        it do
          sketch = described_class.new(**args)

          expect do
            sketch.add(0, 0)
          end.to raise_error(ArgumentError, /must be positive/)
        end
      end
    end
  end

  describe "#merge" do
    test_sizes.each do |size|
      context "when given size: #{size}" do
        it "test_merge_equal" do
          parameters = [[35, 1], [1, 3], [15, 2], [40, 0.5]]
          # for size in test_sizes:
          distribution = EmptyDataset.new(0)
          target_sketch = described_class.new(**args)

          parameters.each do |params|
            sketch = described_class.new(**args)

            Normal.new(size, params[0], params[1]).data.each do |value|
              sketch.add(value)
              distribution.add(value)
            end

            target_sketch.merge(sketch)

            expect(target_sketch.num_values).to eq(distribution.size)
            expect(target_sketch.sum).to be_within(1e-3).of(distribution.sum)
            expect(target_sketch.avg).to be_within(1e-3).of(distribution.avg)

            test_quantiles.each do |q|
              expect(target_sketch).to guarantee_accuracy(distribution, args[:relative_accuracy]).at_quantile(q)
            end
          end
        end
      end
    end

    it "test_merge_unequal" do
      distribution = Lognormal.new
      sketch = described_class.new(**args)
      other = described_class.new(**args)

      rng = Random.new

      distribution.data.each do |value|
        if rng.rand > 0.7
          sketch.add(value)
        else
          other.add(value)
        end
      end

      sketch.merge(other)

      expect(sketch.num_values).to eq(distribution.size)
      expect(sketch.sum).to be_within(1e-3).of(distribution.sum)
      expect(sketch.avg).to be_within(1e-3).of(distribution.avg)

      test_quantiles.each do |q|
        expect(sketch).to guarantee_accuracy(distribution, args[:relative_accuracy]).at_quantile(q)
      end
    end

    it "test_merge_mixed" do
      distribution = EmptyDataset.new(0)
      sketch = described_class.new(**args)

      [
        Normal.new(100),
        Exponential.new,
        Laplace.new,
        Bimodal.new
      ].each do |other_distribution|
        other = described_class.new(**args)

        other_distribution.data.each do |value|
          sketch.add(value)
          distribution.add(value)
        end

        sketch.merge(other)
      end

      expect(sketch.num_values).to eq(distribution.size)
      expect(sketch.sum).to be_within(1e-3).of(distribution.sum)
      expect(sketch.avg).to be_within(1e-3).of(distribution.avg)

      test_quantiles.each do |q|
        expect(sketch).to guarantee_accuracy(distribution, args[:relative_accuracy]).at_quantile(q)
      end
    end

    it "test_consistent_merge" do
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

    context "when two sketch with different gamma" do
      it do
        sketch = described_class.new(relative_accuracy: 0.1)
        other = described_class.new(relative_accuracy: 0.2)

        expect { sketch.merge(other) }.to raise_error(
          Datadog::DDSketch::InvalidSketchMergeError,
          "Cannot merge two sketches with different relative accuracy"
        )
      end
    end
  end
end

shared_examples "sketch protobuf" do
  describe "#to_proto" do
    it "returns a Sketch protobuf" do
      protobuf = subject.to_proto

      expect(protobuf).to be_a(Datadog::DDSketch::Proto::DDSketch)
      expect(protobuf.mapping).to be_a(Datadog::DDSketch::Proto::IndexMapping)
      expect(protobuf.positiveValues).to be_a(Datadog::DDSketch::Proto::Store)
      expect(protobuf.negativeValues).to be_a(Datadog::DDSketch::Proto::Store)
      expect(protobuf.zeroCount).to be_a(Float)
    end
  end
end
