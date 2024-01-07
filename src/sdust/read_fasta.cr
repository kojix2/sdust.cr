require "compress/gzip"

module Sdust
  module ReadFasta
    extend self

    def each_contig(filename : Path | String)
      filename = Path.new(filename)
      File.open(filename) do |file|
        file = Compress::Gzip::Reader.new(file) if filename.extension == ".gz"

        name = nil
        sequence = IO::Memory.new

        file.each_line(chomp = true) do |line|
          if line.starts_with?(">")
            yield name, sequence unless name.nil?
            name = line[1..-1]
            sequence = IO::Memory.new
          else
            if line.ascii_only?
              sequence << line
            else
              raise <<-ERROR
                [wgsim] Non-ASCII characters in FASTA file: #{filename}
                  #{name}
                  #{sequence}
                ERROR
            end
          end
        end

        file.close if filename.extension == ".gz"
        yield name, sequence unless name.nil?
      end
    end
  end
end
