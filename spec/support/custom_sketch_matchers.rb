RSpec::Matchers.define :guarantee_accuracy do |data, eps|
  match do |sketch|
    sketch_q = sketch.get_quantile_value(@quantile)
    data_q = data.quantile(@quantile)
    err = (sketch_q - data_q).abs

    err - eps * data_q.abs <= 1e-15
  end

  chain :at_quantile do |quantile|
    @quantile = quantile
  end
end
