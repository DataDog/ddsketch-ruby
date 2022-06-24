require_relative 'lib/datadog/ddsketch/version'

Gem::Specification.new do |spec|
  spec.name = 'sketches-ruby'
  spec.version = Datadog::DDSketch::Version.to_s
  spec.authors = ['Datadog, Inc.']
  spec.email = ['dev@datadoghq.com']

  spec.summary = "Ruby implementations of the distributed quantile sketch algorithm DDSketch."
  spec.description = "DDSketch has relative error guarantees: it computes quantiles with a controlled relative error. For instance, using DDSketch with a relative accuracy guarantee set to 1%, if the expected quantile value is 100, the computed quantile value is guaranteed to be between 99 and 101. If the expected quantile value is 1000, the computed quantile value is guaranteed to be between 990 and 1010."
  # spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 2.3"

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

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'google-protobuf', ['~> 3.0', '!= 3.7.0', '!= 3.7.1', '< 3.19.2']

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
