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
      @options = parse_options
      @in_file = @options.in_file.not_nil!
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
      {% if flag?(:preview_mt) %}
        STDERR.puts "[sdust] experimental multi-threading mode"
        channel = Channel(Tuple(String, Array(UInt64))).new
        results = Hash(String, Array(UInt64)?).new

        ReadFasta.each_contig(@in_file) do |long_name, sequence|
          name = long_name.split.first
          STDERR.puts "[sdust] #{name} #{sequence.size}bp"
          results[name] = nil
          spawn do
            result = Core.new.sdust(sequence, win_size, threshold)
            channel.send({name, result})
          end
        end
        results.each_key do |name|
          loop do
            unless results[name].nil?
              print_result(name, results[name].not_nil!, io)
              break
            end
            n, r = channel.receive
            results[n] = r
          end
        end
      {% else %}
        ReadFasta.each_contig(@in_file) do |long_name, sequence|
          name = long_name.split.first
          STDERR.puts "[sdust] #{name} #{sequence.size}bp"
          result = Core.new.sdust(sequence, win_size, threshold)
          print_result(name, result, io)
        end
      {% end %}
    end

    def print_result(name, result, io = STDOUT)
      result.each do |r|
        io.puts "#{name}\t#{r >> 32}\t#{r.unsafe_as(Int32)}"
      end
    end
  end
end
