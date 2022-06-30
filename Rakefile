# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :coverage do
  task :report do
    require 'simplecov'

    resultset_files = Dir["#{ENV.fetch('COVERAGE_DIR', 'coverage')}/.resultset.json"] +
                      Dir["#{ENV.fetch('COVERAGE_DIR', 'coverage')}/versions/**/.resultset.json"]

    SimpleCov.collate resultset_files do
      coverage_dir "#{ENV.fetch('COVERAGE_DIR', 'coverage')}/report"
      if ENV['CI'] == 'true'
        require 'codecov'
        formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter,
                                                            SimpleCov::Formatter::Codecov])
      else
        formatter SimpleCov::Formatter::HTMLFormatter
      end
    end
  end

  # Generates one report for each Ruby version
  task :report_per_ruby_version do
    require 'simplecov'

    versions = Dir["#{ENV.fetch('COVERAGE_DIR', 'coverage')}/versions/*"].map { |f| File.basename(f) }
    versions.map do |version|
      puts "Generating report for: #{version}"
      SimpleCov.collate Dir["#{ENV.fetch('COVERAGE_DIR', 'coverage')}/versions/#{version}/**/.resultset.json"] do
        coverage_dir "#{ENV.fetch('COVERAGE_DIR', 'coverage')}/report/versions/#{version}"
        formatter SimpleCov::Formatter::HTMLFormatter
      end
    end
  end
end
