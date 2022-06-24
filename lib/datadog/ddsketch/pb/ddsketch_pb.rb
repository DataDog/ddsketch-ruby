# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: ddsketch.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("ddsketch.proto", :syntax => :proto3) do
    add_message "DDSketch" do
      optional :mapping, :message, 1, "IndexMapping"
      optional :positiveValues, :message, 2, "Store"
      optional :negativeValues, :message, 3, "Store"
      optional :zeroCount, :double, 4
    end
    add_message "IndexMapping" do
      optional :gamma, :double, 1
      optional :indexOffset, :double, 2
      optional :interpolation, :enum, 3, "IndexMapping.Interpolation"
    end
    add_enum "IndexMapping.Interpolation" do
      value :NONE, 0
      value :LINEAR, 1
      value :QUADRATIC, 2
      value :CUBIC, 3
    end
    add_message "Store" do
      map :binCounts, :sint32, :double, 1
      repeated :contiguousBinCounts, :double, 2
      optional :contiguousBinIndexOffset, :sint32, 3
    end
  end
end

DDSketch = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("DDSketch").msgclass
IndexMapping = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("IndexMapping").msgclass
IndexMapping::Interpolation = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("IndexMapping.Interpolation").enummodule
Store = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Store").msgclass
