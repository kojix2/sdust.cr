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
      ReadFasta.each_contig(@in_file) do |name, sequence|
        name = name.split.first
        STDERR.puts "[sdust] #{name} #{sequence.size}bp"
        result = Core.new.sdust(sequence, win_size, threshold)
        result.each do |r|
          puts "#{name}\t#{r >> 32}\t#{r.unsafe_as(Int32)}"
        end
      end
    end
  end
end
