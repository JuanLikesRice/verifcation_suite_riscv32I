#!/usr/bin/env python3
import sys, struct
try:
    import numpy as np
except ImportError:
    raise SystemExit("pip install numpy")

def f32(x): return np.float32(x)

def f32_bits(x_f32):
    return int.from_bytes(struct.pack('>f', float(x_f32)), 'big', signed=False)

def split_fields(bits):
    s = (bits >> 31) & 0x1
    e = (bits >> 23) & 0xFF
    m =  bits        & 0x7FFFFF
    return s, e, m

def fmt_bits(b): return f"0x{b:08X}"
def fmt_s(s):    return f"0x{s:X}"
def fmt_e(e):    return f"0x{e:02X}"
def fmt_m(m):    return f"0x{m:06X}"

def three_col(h1, h2, h3, rows, w=24):
    hdr = f"{h1:<{w}} | {h2:<{w}} | {h3:<{w}}"
    print(hdr)
    print("-" * len(hdr))
    for a,b,c in rows:
        print(f"{a:<{w}} | {b:<{w}} | {c:<{w}}")
    print()

def gather(label_val):
    x = f32(label_val)
    b = f32_bits(x)
    s,e,m = split_fields(b)
    return (
        f"dec: {x}",
        f"bits: {fmt_bits(b)}",
        f"sign: {fmt_s(s)}",
        f"expo: {fmt_e(e)}",
        f"mant: {fmt_m(m)}",
    )

def main(a_str, b_str):
    a = f32(a_str)
    b = f32(b_str)
    o = f32(a + b)

    A = gather(a)
    B = gather(b)
    O = gather(o)

    rows = list(zip(A, B, O))
    three_col("A", "B", "Output", rows)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: fsum32_3col.py <a> <b>")
        print("Example: fsum32_3col.py 1.0 0.1")
        sys.exit(1)
    main(float(sys.argv[1]), float(sys.argv[2]))
