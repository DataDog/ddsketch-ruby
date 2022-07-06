# frozen_string_literal: true

module DDSketch
  module Version
    MAJOR = 0
    MINOR = 1
    PATCH = 0
    PRE = nil

    def self.to_s
      [MAJOR, MINOR, PATCH, PRE].compact.join(".")
    end
  end
end
