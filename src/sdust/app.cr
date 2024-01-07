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

    def parse_options
      parser = Parser.new
      parser.parse
    end

    def run
      {% if flag?(:preview_mt) %}
        STDERR.puts "[sdust] experimental multi-threading mode"
        channel = Channel(Tuple(String, Array(UInt64))).new
        names = [] of String

        ReadFasta.each_contig(@in_file) do |long_name, sequence|
          name = long_name.split.first
          STDERR.puts "[sdust] #{name} #{sequence.size}bp"
          names << name
          spawn do
            result = Core.new.sdust(sequence, win_size, threshold)
            channel.send({name, result})
          end
        end
        results = {} of String => Array(UInt64)
        while (!names.empty?)
          name, result = channel.receive
          if names.first == name
            names.shift
            print_result(name, result)
            while results.has_key?(names.first)
              n = names.shift
              print_result(n, results.delete(n).not_nil!)
            end
          else
            results[name] = result
          end
        end
      {% else %}
        ReadFasta.each_contig(@in_file) do |long_name, sequence|
          name = long_name.split.first
          STDERR.puts "[sdust] #{name} #{sequence.size}bp"
          result = Core.new.sdust(sequence, win_size, threshold)
          print_result(name, result)
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
