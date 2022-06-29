# sketches-ruby

[![CircleCI](https://circleci.com/gh/DataDog/sketches-ruby/tree/main.svg?style=svg)](https://circleci.com/gh/DataDog/sketches-ruby/tree/main)

This repo contains the Ruby implementation of a distributed quantile sketch algorithm [DDSketch](http://www.vldb.org/pvldb/vol12/p2195-masson.pdf).

`DDSketch` has relative-error guarantees for any quantile q in [0, 1]. That is if the true value of the qth-quantile is `x` then `DDSketch` returns a value `y` such that `|x-y| / x < e` where `e` is the relative error parameter. `DDSketch` is also fully mergeable, meaning that multiple sketches from distributed systems can be combined in a central node.

### Installation

In order to support Ruby 2.1 and 2.2. We decided to make `google-protobuf` a soft dependency instead of a hard one in `gemspec`. If `google-protobuf` dependency is not resolved, user can still use it without [protobuf serialization](#protobuf-serialization)

In `Gemfile`

```ruby
gem 'sketches-ruby'
gem 'google-protobuf', '~> 3.0'
```

Verify in interactive console with `Datadog::DDSketch.supported?`

```
% irb -I lib
irb(main):001:0> require 'google/protobuf'
=> true
irb(main):002:0> require 'ddsketch'
=> true
irb(main):003:0> Datadog::DDSketch.supported?
=> true
```


### Usage

Our default implementation is guaranteed not to grow too large in size for any data that can be described by a distribution whose tails are sub-exponential. We also provide implementations where the q-quantile will be accurate up to the specified relative error for q that is not too small (or large). Concretely, the q-quantile will be accurate up to the specified relative error as long as it belongs to one of the bins kept by the sketch. For instance, If the values are time in seconds, `bin_limit = 2048` covers a time range from 80 microseconds to 1 year.


To initialize a sketch with the default parameters (relative_accuracy is 0.01 and bin_limit is 2048)

```ruby
require 'datadog/ddsketch'

Datadog::DDSketch::Sketch.new
// or
Datadog::DDSketch::LogCollapsingHighestDenseSketch.new
// or
Datadog::DDSketch::LogCollapsingLowestDenseSketch.new
```

### Initialize with `relative_accuracy` or `bin_limit`

If you want more granular control over how accurate the sketch's results will be, you can pass a `relative_accuracy` parameter when initializing a sketch.

Whereas other histograms use _rank error_ guarantees (i.e. retrieving the p99 of the histogram will give you a value between p98.9 and p99.1), `DDSketch` uses a _relative error_ guarantee (if the actual value at p99 is 100, the value will be between 99 and 101 for a `relative_accuracy` of 0.01).

This property makes `DDSketch` especially useful for long-tailed distributions of data, like measurements of latency.

```ruby
require 'datadog/ddsketch'

Datadog::DDSketch::Sketch.new(relative_accuracy: relative_accuracy)

Datadog::DDSketch::LogCollapsingHighestDenseSketch.new(
  relative_accuracy: relative_accuracy,    # default is 0.01
  bin_limit: bin_limit                     # default is 2048
)

Datadog::DDSketch::LogCollapsingLowestDenseSketch.new(
  relative_accuracy: relative_accuracy,    # default is 0.01
  bin_limit: bin_limit                     # default is 2048
)
```

### Adding values to a sketch

To add a number to a sketch, call `sketch.add(value)`. Both positive and negative numbers are supported.

```ruby
require 'datadog/ddsketch'

sketch = Datadog::DDSketch::Sketch.new

sketch.add(1607374726)
sketch.add(0)
sketch.add(-3.1415)
```

### Retrieve measurements from the sketch

To retrieve measurements from a sketch, use `sketch.get_quantile_value(quantile)`. Any number between 0 and 1 (inclusive) can be used as a quantile. Additionally, common summary statistics are available such as `sketch.min`, `sketch.max`, `sketch.sum`, and `sketch.count`:

```ruby
require 'datadog/ddsketch'

sketch = Datadog::DDSketch::Sketch.new

sketch.add(1607374726)
sketch.add(0)
sketch.add(-3.1415)

sketch.get_quantile_value(0)     // -3.158156063689099
sketch.get_quantile_value(0.5)   // 0
sketch.get_quantile_value(0.99)  // 0
sketch.get_quantile_value(1)     // 1595824509.0872598

sketch.min     // -3.1415
sketch.max     // 1607374726
sketch.count   // 3.0
sketch.sum     // 1607374722.8585
```

### Merging sketches

Independent sketches can be merged together, provided that they were initialized with the same `relative_accuracy`. This allows collecting and transmitting measurements in a distributed manner, and merging their results together while preserving the `relative_accuracy` guarantee.

```ruby
require 'datadog/ddsketch'

sketch_1 = Datadog::DDSketch::Sketch.new
sketch_2 = Datadog::DDSketch::Sketch.new

[1,2,3,4,5].each { |v| sketch_1.add(v) }
[6,7,8,9,10].each { |v| sketch_2.add(v) }

// sketch_2 is merged into sketch_1, without modifying sketch_2
sketch_1.merge(sketch_2)

sketch_1.get_quantile_value(1)
```

### Protobuf Serialization

`#to_proto` would return Protobuf object

```ruby
require 'google/protobuf'
require 'datadog/ddsketch'

sketch = Datadog::DDSketch::Sketch.new

proto = sketch.to_proto
=> <Datadog::DDSketch::Proto::DDSketch: mapping: <Datadog::DDSketch::Proto::IndexMapping: gamma: 0.01, indexOffset: 0.0, interpolation: :NONE>, positiveValues: <Datadog::DDSketch::Proto::Store: binCounts: {}, contiguousBinCounts: [], contiguousBinIndexOffset: 0>, negativeValues: <Datadog::DDSketch::Proto::Store: binCounts: {}, contiguousBinCounts: [], contiguousBinIndexOffset: 0>, zeroCount: 0.0>

proto.to_h
=> {:mapping=>{:gamma=>0.01, :indexOffset=>0.0, :interpolation=>:NONE}, :positiveValues=>{:binCounts=>{}, :contiguousBinCounts=>[], :contiguousBinIndexOffset=>0}, :negativeValues=>{:binCounts=>{}, :contiguousBinCounts=>[], :contiguousBinIndexOffset=>0}, :zeroCount=>0.0}
```

## References

* [DDSketch: A Fast and Fully-Mergeable Quantile Sketch with Relative-Error Guarantees](http://www.vldb.org/pvldb/vol12/p2195-masson.pdf). Charles Masson, Jee E. Rim and Homin K. Lee. 2019.
* Java implementation: [https://github.com/DataDog/sketches-java](https://github.com/DataDog/sketches-java)
* Go implementation: [https://github.com/DataDog/sketches-go](https://github.com/DataDog/sketches-go)
* Python implementation: [https://github.com/DataDog/sketches-py](https://github.com/DataDog/sketches-py)
