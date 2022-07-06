# frozen_string_literal: true

require "ddsketch/version"
require "ddsketch/errors"

# sketchs
require "ddsketch/base_sketch"
require "ddsketch/sketch"
require "ddsketch/log_collapsing_lowest_dense_sketch"
require "ddsketch/log_collapsing_highest_dense_sketch"

# key mappings
require "ddsketch/mapping/key_mapping"
require "ddsketch/mapping/logarithmic_key_mapping"
require "ddsketch/mapping/linear_interpolated_key_mapping"
require "ddsketch/mapping/cubically_interpolated_key_mapping"

# dense stores
require "ddsketch/store/dense_store"
require "ddsketch/store/collapsing_lowest_dense_store"
require "ddsketch/store/collapsing_highest_dense_store"

# protobuf
require "ddsketch/proto"

# Namespace for DDSketch library
module DDSketch
  GOOGLE_PROTOBUF_MINIMUM_VERSION = Gem::Version.new("3.0")
  private_constant :GOOGLE_PROTOBUF_MINIMUM_VERSION

  # @return [Boolean] if `google-protobuf` is loaded sucessfully
  def self.protobuf_gem_loaded_successfully?
    protobuf_gem_loading_issue.nil?
  end

  # @return [String, nil] the description about failing to load `google-protobuf`
  def self.protobuf_gem_loading_issue
    protobuf_gem_unavailable? ||
      protobuf_version_unsupported? ||
      protobuf_failed_to_load?
  end

  private_class_method def self.protobuf_gem_unavailable?
    # NOTE: On environments where protobuf is already loaded, we skip the check. This allows us to support environments
    # where no Gem.loaded_version is NOT available but customers are able to load protobuf; see for instance
    # https://github.com/teamcapybara/capybara/commit/caf3bcd7664f4f2691d0ca9ef3be9a2a954fecfb
    if !defined?(::Google::Protobuf) && Gem.loaded_specs["google-protobuf"].nil?
      "Missing google-protobuf dependency; please add `gem 'google-protobuf', '~> 3.0'` to your Gemfile or gems.rb file"
    end
  end

  private_class_method def self.protobuf_version_unsupported?
    # See above for why we skip the check when protobuf is already loaded; note that when protobuf was already loaded
    # we skip the version check to avoid the call to Gem.loaded_specs. Unfortunately, protobuf does not seem to
    # expose the gem version constant elsewhere, so in that setup we are not able to check the version.
    if !defined?(::Google::Protobuf) && Gem.loaded_specs["google-protobuf"].version < GOOGLE_PROTOBUF_MINIMUM_VERSION
      "Your google-protobuf is too old; ensure that you have google-protobuf >= 3.0 by " \
      "adding `gem 'google-protobuf', '~> 3.0'` to your Gemfile or gems.rb file"
    end
  end

  private_class_method def self.protobuf_failed_to_load?
    unless protobuf_required_successfully?
      "There was an error loading the google-protobuf library; see previous warning message for details"
    end
  end

  # The `google-protobuf` gem depends on a native component, and its creators helpfully tried to provide precompiled
  # versions of this extension on rubygems.org.
  #
  # Unfortunately, for a long time, the supported Ruby versions metadata on these precompiled versions of the extension
  # was not correctly set. (This is fixed in newer versions -- but not all Ruby versions we want to support can use
  # these.)
  #
  # Thus, the gem can still be installed, but can be in a broken state. To avoid breaking customer applications, we
  # use this helper to load it and gracefully handle failures.
  private_class_method def self.protobuf_required_successfully?
    return @protobuf_loaded if defined?(@protobuf_loaded)

    begin
      require "google/protobuf"
      @protobuf_loaded = true
    rescue LoadError => e
      Kernel.warn(
        "[DDSKETCH] Error while loading google-protobuf gem. " \
        "Cause: '#{e.class.name} #{e.message}' Location: '#{Array(e.backtrace).first}'. " \
        "This can happen when google-protobuf is missing its native components. " \
        "To fix this, try removing and reinstalling the gem, forcing it to recompile the components: " \
        "`gem uninstall google-protobuf -a; BUNDLE_FORCE_RUBY_PLATFORM=true bundle install`. " \
        "If the error persists, please contact Datadog support at <https://docs.datadoghq.com/help/>."
      )
      @protobuf_loaded = false
    end
  end

  private_class_method def self.load_ddsketch
    return unless protobuf_gem_loaded_successfully?

    require "ddsketch/pb/ddsketch_pb"

    true
  end

  load_ddsketch
end
