# Isolates the algorithm from program startup/output and quantifies allocation.
# Build: crystal build --release benchmark/scripts/bench_core.cr -o benchmark/scripts/bench_core
require "../../src/sdust/read_fasta"
require "../../src/sdust/core"

file = ARGV[0]
win = (ARGV[1]? || "64").to_i
thr = (ARGV[2]? || "20").to_i

# Load all contigs into memory first so I/O is excluded from the measured region.
contigs = [] of {String, IO::Memory}
Sdust::ReadFasta.each_contig(file) do |name, seq|
  contigs << {name.not_nil!, seq}
end
total_bp = contigs.sum { |(_, s)| s.size }
STDERR.puts "loaded #{contigs.size} contig(s), #{total_bp} bp"

mb = ->(x : UInt64) { (x.to_f / 1e6).round(1) }

# --- normalize_sequence alone ---
GC.collect
b = GC.stats
t0 = Time.monotonic
contigs.each { |(_, s)| Sdust::ReadFasta.normalize_sequence(s) }
t1 = Time.monotonic
a = GC.stats
puts "[normalize] time=#{(t1 - t0).total_seconds.round(3)}s  allocated=#{mb.call(a.total_bytes - b.total_bytes)}MB"

# --- full core (sdust) including its internal normalize ---
GC.collect
b = GC.stats
t0 = Time.monotonic
intervals = 0_i64
contigs.each do |(_, s)|
  res = Sdust::Core.new.sdust(s, win, thr)
  intervals += res.size
end
t1 = Time.monotonic
a = GC.stats
puts "[core+norm] time=#{(t1 - t0).total_seconds.round(3)}s  allocated=#{mb.call(a.total_bytes - b.total_bytes)}MB  intervals=#{intervals}"
puts "[gc] heap_size=#{mb.call(a.heap_size)}MB  total_bytes(cumulative)=#{mb.call(a.total_bytes)}MB"
