require "./parser"
require "./options"
require "./read_fasta"
require "./core"

module Sdust
  class App
    getter options : Options
    getter in_file : Path
    delegate win_size, threshold, to: @options

    def self.run
      new.run
    end

    def initialize
      options = parse_options
      @options = options
      @in_file = options.in_file || raise "missing input file"
    end

    def initialize(in_file : Path | String, win_size : Int32, threshold : Int32)
      in_file = Path.new(in_file)
      @options = Options.new(in_file, win_size, threshold)
      @in_file = in_file
    end

    def parse_options
      parser = Parser.new
      parser.parse
    end

    def run(io = STDOUT)
      starting_time = Time.local
      STDERR.puts "[sdust] starting sdust with window size: #{win_size} and threshold: #{threshold} at #{starting_time}"

      Fastx::Fasta::Reader.open(@in_file) do |reader|
        reader.each_record_lines do |header, lines|
          name = header.split.first
          length = 0
          core = Core.new.start(win_size, threshold)

          lines.each do |line|
            length += line.size
            core.feed(line)
          end

          STDERR.puts "[sdust] #{name} #{length}bp"
          print_result(name, core.finish, io)
        end
      end

      elapsed_time = (Time.local - starting_time).total_seconds
      STDERR.puts "[sdust] finished at #{Time.local} (#{elapsed_time.round(2)}s)"
    end

    def print_result(name, result, io = STDOUT)
      result.each do |region|
        io << name << '\t' << (region >> 32) << '\t' << region.unsafe_as(Int32) << '\n'
      end
    end
  end
end
