require "./parser"
require "./options"
require "./read_fasta"
require "./core"

{% if flag?(:execution_context) && flag?(:preview_mt) %}
  require "fiber/execution_context"
  require "wait_group"
{% end %}

module Sdust
  class App
    private struct Contig
      getter index : Int32
      getter name : String
      getter length : Int32
      getter sequence : IO::Memory

      def initialize(@index, @name, @length, @sequence)
      end
    end

    private struct ContigResult
      getter index : Int32
      getter name : String
      getter length : Int32
      getter regions : Array(Core::MaskedRegion)

      def initialize(@index, @name, @length, @regions)
      end
    end

    getter options : Options
    getter in_file : Path
    delegate win_size, threshold, threads, to: @options

    def self.run
      new.run
    end

    def initialize
      options = parse_options
      @options = options
      @in_file = options.in_file || raise "missing input file"
    end

    def initialize(in_file : Path | String, win_size : Int32, threshold : Int32, threads : Int32 = 1)
      in_file = Path.new(in_file)
      @options = Options.new(in_file, win_size, threshold, threads)
      @in_file = in_file
    end

    def parse_options
      parser = Parser.new
      parser.parse
    end

    def run(io = STDOUT)
      workers = worker_count
      {% unless flag?(:execution_context) && flag?(:preview_mt) %}
        if workers != 1
          Utils.print_error!("--threads requires a binary built with -Dpreview_mt -Dexecution_context")
        end
      {% end %}

      starting_time = Time.local
      STDERR.puts "[sdust] starting sdust with window size: #{win_size} and threshold: #{threshold} at #{starting_time}"

      {% if flag?(:execution_context) && flag?(:preview_mt) %}
        if workers > 1
          Fiber::ExecutionContext.default.resize(workers)
          run_parallel(io, workers)
        else
          run_serial(io)
        end
      {% else %}
        run_serial(io)
      {% end %}

      elapsed_time = (Time.local - starting_time).total_seconds
      STDERR.puts "[sdust] finished at #{Time.local} (#{elapsed_time.round(2)}s)"
    end

    private def worker_count : Int32
      {% if flag?(:execution_context) && flag?(:preview_mt) %}
        threads == 0 ? Fiber::ExecutionContext.default_workers_count : threads
      {% else %}
        threads
      {% end %}
    end

    private def run_serial(io)
      index = 0

      Fastx::Fasta::Reader.open(@in_file) do |reader|
        reader.each_record_lines do |header, lines|
          result = process_record_stream(index, header, lines)
          log_result(result)
          print_result(result.name, result.regions, io)
          index += 1
        end
      end
    end

    {% if flag?(:execution_context) && flag?(:preview_mt) %}
      private def run_parallel(io, workers : Int32)
        jobs = Channel(Contig).new
        results = Channel(ContigResult | Exception).new(workers)
        done = Channel(Int32 | Exception).new(1)
        worker_group = WaitGroup.new(workers)

        workers.times { spawn process_contigs(jobs, results, worker_group) }
        spawn produce_contigs(jobs, results, done)

        collect_results(results, done, io)
        worker_group.wait
      end

      private def produce_contigs(jobs : Channel(Contig), results : Channel(ContigResult | Exception), done : Channel(Int32 | Exception))
        count = 0

        begin
          Fastx::Fasta::Reader.open(@in_file) do |reader|
            reader.each_record_lines do |header, lines|
              jobs.send(read_contig(count, header, lines))
              count += 1
            end
          end

          jobs.close
          done.send(count)
        rescue ex
          jobs.close
          done.send(ex)
        end
      end

      private def process_contigs(jobs : Channel(Contig), results : Channel(ContigResult | Exception), worker_group : WaitGroup)
        while contig = jobs.receive?
          begin
            results.send(process_contig(contig))
          rescue ex
            results.send(ex)
          end
        end
      ensure
        worker_group.done
      end

      private def collect_results(results : Channel(ContigResult | Exception), done : Channel(Int32 | Exception), io)
        # Keep FASTA order even when worker completion order differs.
        pending = {} of Int32 => ContigResult
        next_index = 0
        received = 0
        expected = nil.as(Int32?)

        loop do
          break if expected && received == expected

          select
          when message = results.receive
            raise message if message.is_a?(Exception)

            received += 1
            pending[message.index] = message
            while result = pending.delete(next_index)
              log_result(result)
              print_result(result.name, result.regions, io)
              next_index += 1
            end
          when total = done.receive
            raise total if total.is_a?(Exception)

            expected = total
          end
        end
      end
    {% end %}

    private def process_record_stream(index : Int32, header, lines) : ContigResult
      name = header.split.first
      length = 0
      core = Core.new.start(win_size, threshold)

      lines.each do |line|
        length += line.size
        core.feed(line)
      end

      ContigResult.new(index, name, length, core.finish)
    end

    private def read_contig(index : Int32, header, lines) : Contig
      name = header.split.first
      length = 0
      sequence = IO::Memory.new

      lines.each do |line|
        length += line.size
        sequence.write(line)
      end

      Contig.new(index, name, length, sequence)
    end

    private def process_contig(contig : Contig) : ContigResult
      regions = Core.new.sdust(contig.sequence, win_size, threshold)
      ContigResult.new(contig.index, contig.name, contig.length, regions)
    end

    private def log_result(result : ContigResult)
      STDERR.puts "[sdust] #{result.name} #{result.length}bp"
    end

    def print_result(name, result, io = STDOUT)
      result.each do |region|
        io << name << '\t' << region.start << '\t' << region.finish << '\n'
      end
    end
  end
end
