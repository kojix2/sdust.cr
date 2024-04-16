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
      Version: #{Sdust::VERSION} (multi-threading: #{{{flag?(:preview_mt)}}})
      Source:  https://github.com/kojix2/sdust.cr

      Usage: sdust [options] <in.fa>
      BANNER
      setup_options
    end

    def setup_options
      on("-w", "--window SIZE", "Window size [#{options.win_size}]") { |v| options.win_size = v.to_i }
      on("-t", "--threshold SIZE", "Threshold size [#{options.threshold}]") { |v| options.threshold = v.to_i }
      {% if flag?(:preview_mt) %}
        on("-@", "--threads INT", "Number of threads [4]") { |v| set_threads(v.to_i) }
      {% end %}
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
      options.in_file = Path.new(argv.first)
      validate_file_exists(options.in_file)
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

    def validate_file_exists(file)
      Utils.print_error!("File not found: #{file}") unless File.exists?(file.not_nil!)
    end

    {% if flag?(:preview_mt) %}
      private def set_threads(n)
        case n
        when 1..3
          (4 - n).times { Crystal::Scheduler.remove_worker }
        when 4
        when 5..
          (n - 4).times { Crystal::Scheduler.add_worker }
        else
          Utils.print_error!("Invalid number of threads: #{n}")
        end
      end
    {% end %}
  end
end
