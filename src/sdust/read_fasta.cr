require "fastx"

module Sdust
  module ReadFasta
    extend self

    NT4_TABLE = begin
      table = StaticArray(UInt8, 256).new(4u8)
      table[65] = table[97] = 0u8  # A/a
      table[67] = table[99] = 1u8  # C/c
      table[71] = table[103] = 2u8 # G/g
      table[84] = table[116] = 3u8 # T/t
      table
    end

    def each_contig(filename : Path | String, &)
      Fastx::Fasta::Reader.open(filename) do |reader|
        reader.each_record_lines do |name, lines|
          sequence = IO::Memory.new
          lines.each do |line|
            sequence.write(line)
          end
          yield name, sequence
        end
      end
    end

    def normalize_sequence(sequence : IO::Memory | String)
      sequence.to_slice.map do |byte|
        normalize_base(byte)
      end
    end

    @[AlwaysInline]
    def normalize_base(byte : UInt8) : UInt8
      b = NT4_TABLE[byte.to_i]
      STDERR.puts "[sdust] '#{byte.chr}' is replaced with 'N'" if b == 4u8 && byte != 78u8 && byte != 110u8
      b
    end
  end
end
