# frozen_string_literal: true

shared_context 'mapping tests' do
  def relative_error(expected_min, expected_max, actual)
    raise if (expected_min < 0) || (expected_max < 0) || (actual < 0)
    return 0.0 if (expected_min <= actual) && (actual <= expected_max)

    if (expected_min == 0) && (expected_max == 0)
      if actual == 0
        return 0.0
      else
        Float::INFINITY
      end
    end
    return (expected_min - actual) / expected_min if actual < expected_min

    (actual - expected_max) / expected_max
  end

  # Calculate the relative accuracy of a mapping on a large range of values
  def test_value_rel_acc(mapping)
    value_mult = 2 - Math.sqrt(2) * 1e-1
    max_relative_acc = 0.0
    value = mapping.min_possible
    while value < mapping.max_possible / value_mult
      value *= value_mult
      map_val = mapping.value(mapping.key(value))
      rel_err = relative_error(value, value, map_val)
      expect(rel_err).to be < mapping.relative_accuracy
      max_relative_acc = [max_relative_acc, rel_err].max
    end

    [
      max_relative_acc,
      relative_error(
        mapping.max_possible,
        mapping.max_possible,
        mapping.value(mapping.key(mapping.max_possible)),
      ),
    ].max
  end

  let(:mapping) {}

  # Test the mapping on a large range of relative accuracies
  begin
    let(:offset) { 0.0 }
    rel_acc_mult = 1 - Math.sqrt(2) * 1e-1
    min_rel_acc = 1e-8
    rel_acc = 1 - 1e-3

    while rel_acc >= min_rel_acc
      rel_acc.tap do |relative_accuracy| # Create closure to ensure relative_accuracy is different for each example
        context "with accuracy #{relative_accuracy}" do
          let(:relative_accuracy) { relative_accuracy }

          it 'test accuracy' do
            max_rel_acc = test_value_rel_acc(mapping)
            expect(max_rel_acc).to be < mapping.relative_accuracy
          end
        end
      end
      rel_acc *= rel_acc_mult
    end
  end

  begin
    let(:relative_accuracy) { 0.01 }

    [0, 1, -12.23, 7768.3].each do |offset|
      context "with offset #{offset}" do
        let(:offset) { offset }

        it 'test offset' do
          expect(mapping.key(1)).to eq(Integer(offset))
        end
      end
    end
  end
end
