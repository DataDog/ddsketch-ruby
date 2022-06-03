RSpec::Matchers.define :maintain_weighted_indexed_bins_for do |values|
  counter = values.each_with_object(Hash.new(0)) do |v, hash|
    hash[v] += 1
  end

  match do |store|
    store.bins.each_with_index do |bin, index|
      expect(bin).to eq(counter.fetch(index + store.offset)) if bin != 0
    end
  end
end
