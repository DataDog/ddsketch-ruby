# frozen_string_literal: true

describe 'DDSketch' do
  test_rel_acc = 0.05

  describe DDSketch::DDSketch do
    it_behaves_like 'test sketch', test_rel_acc
  end

  describe DDSketch::LogCollapsingLowestDenseDDSketch do
    it_behaves_like 'test sketch', test_rel_acc, 1024
  end

  describe DDSketch::LogCollapsingHighestDenseDDSketch do
    it_behaves_like 'test sketch', test_rel_acc, 1024
  end
end
