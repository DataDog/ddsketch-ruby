# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :coverage do
  task :report do
    require "simplecov"

    resultset_files = Dir["#{ENV.fetch("COVERAGE_DIR", "coverage")}/.resultset.json"] +
      Dir["#{ENV.fetch("COVERAGE_DIR", "coverage")}/versions/**/.resultset.json"]

    SimpleCov.collate resultset_files do
      coverage_dir "#{ENV.fetch("COVERAGE_DIR", "coverage")}/report"
      if ENV["CI"] == "true"
        require "codecov"
        formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter,
          SimpleCov::Formatter::Codecov])
      else
        formatter SimpleCov::Formatter::HTMLFormatter
      end
    end
  end

  # Generates one report for each Ruby version
  task :report_per_ruby_version do
    require "simplecov"

    versions = Dir["#{ENV.fetch("COVERAGE_DIR", "coverage")}/versions/*"].map { |f| File.basename(f) }
    versions.map do |version|
      puts "Generating report for: #{version}"
      SimpleCov.collate Dir["#{ENV.fetch("COVERAGE_DIR", "coverage")}/versions/#{version}/**/.resultset.json"] do
        coverage_dir "#{ENV.fetch("COVERAGE_DIR", "coverage")}/report/versions/#{version}"
        formatter SimpleCov::Formatter::HTMLFormatter
      end
    end
  end
end

YARD::Rake::YardocTask.new(:docs) do |t|
  # Options defined in `.yardopts` are read first, then merged with
  # options defined here.
  #
  # It's recommended to define options in `.yardopts` instead of here,
  # as `.yardopts` can be read by external YARD tools, like the
  # hot-reload YARD server `yard server --reload`.

  t.options += ["--title", "ddsketch #{DDSketch::Version} documentation"]
end

# Deploy tasks
S3_BUCKET = "gems.datadoghq.com"
S3_DIR = ENV["S3_DIR"]

desc "release the docs website"
task "release:docs": :docs do
  raise "Missing environment variable S3_DIR" if !S3_DIR || S3_DIR.empty?

  sh "aws s3 cp --recursive doc/ s3://#{S3_BUCKET}/#{S3_DIR}/docs/"
end

namespace :changelog do
  task :format do
    require "pimpmychangelog"

    PimpMyChangelog::CLI.run!
  end
end
