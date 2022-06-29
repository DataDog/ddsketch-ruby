# frozen_string_literal: true

require 'datadog/ddsketch/version'
require 'datadog/ddsketch/errors'

# sketchs
require 'datadog/ddsketch/base_ddsketch'
require 'datadog/ddsketch/sketch'
require 'datadog/ddsketch/log_collapsing_lowest_dense_sketch'
require 'datadog/ddsketch/log_collapsing_highest_dense_sketch'

# key mappings
require 'datadog/ddsketch/mapping/key_mapping'
require 'datadog/ddsketch/mapping/logarithmic_key_mapping'
require 'datadog/ddsketch/mapping/linear_interpolated_key_mapping'
require 'datadog/ddsketch/mapping/cubically_interpolated_key_mapping'

# dense stores
require 'datadog/ddsketch/store/dense_store'
require 'datadog/ddsketch/store/collapsing_lowest_dense_store'
require 'datadog/ddsketch/store/collapsing_highest_dense_store'

# protobuf
require 'datadog/ddsketch/proto'

module Datadog
  module DDSketch
    GOOGLE_PROTOBUF_MINIMUM_VERSION = Gem::Version.new('3.0')
    private_constant :GOOGLE_PROTOBUF_MINIMUM_VERSION

    def self.supported?
      unsupported_reason.nil?
    end

    def self.unsupported_reason
      # NOTE: Only the first matching reason is returned, so try to keep a nice order on reasons -- e.g. tell users
      # first that they can't use this on JRuby before telling them that they are missing protobuf
      protobuf_gem_unavailable? ||
        protobuf_version_unsupported? ||
        protobuf_failed_to_load?
    end

    private_class_method def self.protobuf_gem_unavailable?
      # NOTE: On environments where protobuf is already loaded, we skip the check. This allows us to support environments
      # where no Gem.loaded_version is NOT available but customers are able to load protobuf; see for instance
      # https://github.com/teamcapybara/capybara/commit/caf3bcd7664f4f2691d0ca9ef3be9a2a954fecfb
      if !defined?(::Google::Protobuf) && Gem.loaded_specs['google-protobuf'].nil?
        "Missing google-protobuf dependency; please add `gem 'google-protobuf', '~> 3.0'` to your Gemfile or gems.rb file"
      end
    end

    private_class_method def self.protobuf_version_unsupported?
      # See above for why we skip the check when protobuf is already loaded; note that when protobuf was already loaded
      # we skip the version check to avoid the call to Gem.loaded_specs. Unfortunately, protobuf does not seem to
      # expose the gem version constant elsewhere, so in that setup we are not able to check the version.
      if !defined?(::Google::Protobuf) && Gem.loaded_specs['google-protobuf'].version < GOOGLE_PROTOBUF_MINIMUM_VERSION
        'Your google-protobuf is too old; ensure that you have google-protobuf >= 3.0 by ' \
        "adding `gem 'google-protobuf', '~> 3.0'` to your Gemfile or gems.rb file"
      end
    end

    private_class_method def self.protobuf_failed_to_load?
      unless protobuf_loaded_successfully?
        'There was an error loading the google-protobuf library; see previous warning message for details'
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
    private_class_method def self.protobuf_loaded_successfully?
      return @protobuf_loaded if defined?(@protobuf_loaded)

      begin
        require 'google/protobuf'
        @protobuf_loaded = true
      rescue LoadError => e
        # NOTE: We use Kernel#warn here because this code gets run BEFORE Datadog.logger is actually set up.
        # In the future it'd be nice to shuffle the logger startup to happen first to avoid this special case.
        Kernel.warn(
          '[DDTRACE] Error while loading google-protobuf gem. ' \
          "Cause: '#{e.class.name} #{e.message}' Location: '#{Array(e.backtrace).first}'. " \
          'This can happen when google-protobuf is missing its native components. ' \
          'To fix this, try removing and reinstalling the gem, forcing it to recompile the components: ' \
          '`gem uninstall google-protobuf -a; BUNDLE_FORCE_RUBY_PLATFORM=true bundle install`. ' \
          'If the error persists, please contact Datadog support at <https://docs.datadoghq.com/help/>.'
        )
        @protobuf_loaded = false
      end
    end

    private_class_method def self.load_ddsketch
      return false unless supported?

      require 'datadog/ddsketch/pb/ddsketch_pb'

      true
    end

    load_ddsketch
  end
end
