# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :test do
  gem 'distribution'
  # prime is required by distribution, as of Ruby 3.1, the prime gem is
  # no longer distributed as a part of the standard library and must be
  # bundled explicitly.
  gem 'prime'
  gem 'pry'
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rubocop', require: false
  gem 'simplecov', require: false
end

if RUBY_PLATFORM == 'java' || RUBY_VERSION >= '2.5.0'
  gem 'google-protobuf', ['~> 3.0', '!= 3.7.0', '!= 3.7.1']
else
  gem 'google-protobuf', ['~> 3.0', '!= 3.7.0', '!= 3.7.1', '< 3.19.2']
end
