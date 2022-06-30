# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :test do
  gem 'distribution'
  # prime is required by distribution, as of Ruby 3.1, the prime gem is
  # no longer distributed as a part of the standard library and must be
  # bundled explicitly.
  gem "prime"
  gem "pry"
  gem "rake"
  gem "rspec"
  gem "rspec_junit_formatter"
  gem "rubocop", require: false
  gem "standard" if RUBY_VERSION >= "2.2.0"
end

if RUBY_VERSION >= '2.5.0'
  # Merging branch coverage results does not work for old, unsupported rubies.
  # We have a fix up for review, https://github.com/simplecov-ruby/simplecov/pull/972,
  # but given it only affects unsupported version of Ruby, it might not get merged.
    gem 'simplecov', git: 'https://github.com/DataDog/simplecov', ref: '3bb6b7ee58bf4b1954ca205f50dd44d6f41c57db'
  else
    # Compatible with older rubies. This version still produces compatible output
    # with a newer version when the reports are merged.
    gem 'simplecov', '~> 0.17'
  end

if RUBY_PLATFORM == 'java' || RUBY_VERSION >= '2.5.0'
  gem 'google-protobuf', ['~> 3.0', '!= 3.7.0', '!= 3.7.1']
else
  gem 'google-protobuf', ['~> 3.0', '!= 3.7.0', '!= 3.7.1', '< 3.19.2']
end
