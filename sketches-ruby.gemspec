require_relative "lib/datadog/ddsketch/version"

Gem::Specification.new do |spec|
  spec.name = "sketches-ruby"
  spec.version = Datadog::DDSketch::Version.to_s
  spec.authors = ["Datadog, Inc."]
  spec.email = ["dev@datadoghq.com"]

  spec.summary = "Ruby implementations of the distributed quantile sketch algorithm DDSketch."
  spec.description = "DDSketch is a fast-to-insert, fully mergeable, space-efficient quantile sketch with relative error guarantees."
  # spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 2.1.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
