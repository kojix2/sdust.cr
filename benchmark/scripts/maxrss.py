#!/usr/bin/env python3
# Run a command, report wall time and peak RSS (ru_maxrss, KiB on Linux) of the child.
import sys, os, time, resource, subprocess

cmd = sys.argv[1:]
t0 = time.perf_counter()
with open(os.devnull, "wb") as devnull:
    p = subprocess.Popen(cmd, stdout=devnull, stderr=devnull)
    pid, status, ru = os.wait4(p.pid, 0)
t1 = time.perf_counter()
print(f"{ru.ru_maxrss/1024:.1f} MB peak\t{t1-t0:.3f} s\t{' '.join(cmd)}")
