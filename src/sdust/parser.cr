require "./version"
require "./options"
require "./utils"

require "option_parser"

module Sdust
  class Parser < OptionParser
    getter options : Options

    def initialize
      super
      @options = Options.new
      @banner = <<-BANNER

        Program: sdust (Crystal implementation of sdust)
        Version: #{Sdust::VERSION}
        Source:  https://github.com/kojix2/sdust.cr

        Usage: sdust [options] <in.fa>
        BANNER
      setup_options
    end

    def setup_options
      self.summary_width = 24
      on("-w", "--window SIZE", "Window size [#{options.win_size}]") { |v| options.win_size = v.to_i }
      on("-t", "--threshold SIZE", "Threshold size [#{options.threshold}]") { |v| options.threshold = v.to_i }
      on("-@", "--threads COUNT", "Worker threads [#{options.threads}]") { |v| options.threads = v.to_i }
      on("-h", "--help", "Show this message") { show_help }
      on("-v", "--version", "Show version") { show_version }
      invalid_option { |flag| Utils.print_error!("Invalid option: #{flag}") }
    end

    def show_version
      puts Sdust::VERSION
      exit
    end

    def show_help
      puts self
      exit
    end

    def parse(argv = ARGV) : Options
      super
      validate_arguments(argv)
      in_file = Path.new(argv.first)
      options.in_file = in_file
      validate_non_negative("threads", options.threads)
      validate_file_exists(in_file)
      options
    end

    def validate_arguments(argv)
      case argv.size
      when 1
        # OK
      when 0
        STDERR.puts self
        exit 1
      else
        Utils.print_error!("Invalid arguments")
        exit 1
      end
    end

    def validate_file_exists(file : Path)
      Utils.print_error!("File not found: #{file}") unless File.exists?(file)
    end

    def validate_non_negative(name : String, value : Int32)
      Utils.print_error!("#{name} must be non-negative") if value < 0
    end
  end
end
