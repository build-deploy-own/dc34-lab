#!/usr/bin/env python3
"""
sentinel-scan.py - search a live process's readable memory for one literal string.

Usage:  sudo python3 sentinel-scan.py <PID> <SENTINEL>

Workshop demonstration tool for CI/CD Weaponization, Module 2, Step 6.
It looks for a single known value and reports where it was found. It does not
extract, classify or exfiltrate anything.

Why it is written this way
--------------------------
1. A plain `grep` against /proc/<pid>/mem fails. That file exposes the whole
   virtual address space, including unmapped holes, so a sequential read dies
   at the first gap. We parse /proc/<pid>/maps and seek only to readable,
   non-file-backed ranges.

2. Reading another process's memory needs CAP_SYS_PTRACE. Run with sudo, or
   set kernel.yama.ptrace_scope=0 on the disposable lab VM.

3. Runner.Worker is a .NET process and stores managed strings in UTF-16
   little endian. An ASCII-only search returns ZERO matches against it.
   Both encodings are tried, and the report shows which one hit. That
   distinction is the teaching point of the module: a zero in ASCII proves
   the value is not in the process environment block.
"""

import sys

MAX_REGION = 512 * 1024 * 1024   # skip absurdly large mappings
CHUNK = 8 * 1024 * 1024          # read in slices, with overlap


def readable_regions(pid):
    """Readable, non-file-backed ranges from /proc/<pid>/maps."""
    regions = []
    with open(f"/proc/{pid}/maps") as f:
        for line in f:
            parts = line.split()
            if len(parts) < 5:
                continue
            addr, perms = parts[0], parts[1]
            path = parts[5] if len(parts) > 5 else ""
            if "r" not in perms:
                continue
            # File-backed mappings are the binary and its libraries; skip them.
            if path.startswith("/") or path in ("[vvar]", "[vsyscall]"):
                continue
            start, end = (int(x, 16) for x in addr.split("-"))
            if end - start > MAX_REGION:
                continue
            regions.append((start, end, path or "[anon]"))
    return regions


def scan(pid, needle):
    """Return [(address, region_label)] for every occurrence of needle."""
    hits = []
    overlap = len(needle) - 1
    with open(f"/proc/{pid}/mem", "rb", 0) as mem:
        for start, end, region in readable_regions(pid):
            pos, tail = start, b""
            while pos < end:
                size = min(CHUNK, end - pos)
                try:
                    mem.seek(pos)
                    chunk = mem.read(size)
                except (OSError, ValueError, OverflowError):
                    # Region became unreadable mid-scan. Normal; move on.
                    break
                if not chunk:
                    break
                buf = tail + chunk
                base = pos - len(tail)
                off = buf.find(needle)
                while off != -1:
                    hits.append((base + off, region))
                    off = buf.find(needle, off + 1)
                # Carry the tail so a match spanning two chunks is not missed.
                tail = buf[-overlap:] if overlap else b""
                pos += size
    return hits


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    pid, sentinel = sys.argv[1], sys.argv[2]

    encodings = [
        ("utf-8", "ASCII / UTF-8"),
        ("utf-16-le", "UTF-16LE (.NET managed string)"),
    ]

    print(f"[*] Target   : PID {pid}")
    print(f"[*] Sentinel : {sentinel}\n")

    total = 0
    for enc, label in encodings:
        hits = scan(pid, sentinel.encode(enc))
        total += len(hits)
        print(f"[{label}]  {len(hits)} match(es)")
        for addr, region in hits[:5]:
            print(f"    0x{addr:012x}  in {region}")
        if len(hits) > 5:
            print(f"    ... and {len(hits) - 5} more")
        print()

    if total:
        print(f"[!] The value is in plaintext in process memory "
              f"({total} location(s)).")
        print("[!] The log for the same job shows ***.")
    else:
        print("[ ] No matches. See the troubleshooting notes in the playbook.")


if __name__ == "__main__":
    main()
