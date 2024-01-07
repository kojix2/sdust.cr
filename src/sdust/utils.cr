require "colorize"

module Sdust
  module Utils
    def self.print_error!(message : String, color = :default)
      STDERR.print "[sdust] ".colorize.mode(:bold)
      STDERR.puts message.colorize.fore(color).mode(:bold)
      exit 1
    end
  end
end
