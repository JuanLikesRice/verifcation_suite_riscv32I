import struct, csv, numpy as np, cocotb
from cocotb.triggers import Timer

# ---------- helpers ----------
def f32_from_bits(u):
    return np.float32(struct.unpack(">f", u.to_bytes(4, "big", signed=False))[0])

def bits_from_f32(x):
    b = struct.pack(">f", float(np.float32(x)))
    return int.from_bytes(b, "big", signed=False)

def f32_from_hex(h):
    return f32_from_bits(int(h, 16))

def hex_from_bits(u):
    return f"0x{u:08X}"

def split_fields(u):
    return (u >> 31) & 1, (u >> 23) & 0xFF, u & 0x7FFFFF

def fmt_fields(u):
    s,e,m = split_fields(u)
    return f"s=0x{s:X} e=0x{e:02X} m=0x{m:06X}"

def same_fp32_bits(exp_bits, got_bits):
    if (exp_bits & 0x7FFFFFFF) == 0 and (got_bits & 0x7FFFFFFF) == 0:
        return True
    def is_nan(u): return (u & 0x7F800000) == 0x7F800000 and (u & 0x007FFFFF) != 0
    if is_nan(exp_bits) and is_nan(got_bits):
        return True
    return exp_bits == got_bits

def f32_dec_str(x):  # stable decimal text from float32
    return repr(float(np.float32(x)))

# (rm, A_hex, B_hex)
VECTORS = [
    (0b000, "0x3FA00000", "0x3FB00000"),
    (0b000, "0x3FA00000", "0x443BD800"),
    (0b000, "0x3FA00000", "0x3FA00000"),
    (0b000, "0xBFC00000", "0x3FA00000"),
    (0b000, "0x00000000", "0x80000000"),
    (0b000, "0x3F800000", "0x2F000000"),
    (0b000, "0x5F1B3E64", "0x5F1B3E64"),
    (0b000, "0x7F800000", "0x3F800000"),
    (0b000, "0x7FC00001", "0x40000000"),
    (0b000, "0x00000080", "0x3F000000"),
    (0b001, "0x3E99999A", "0x3E99999A"),
    (0b010, "0x3E99999A", "0x3E4CCCCD"),
    (0b011, "0x3F000000", "0x00000001"),
    (0b000, "0xC2480000", "0x42480000"),
]

@cocotb.test()
async def check_fpu_adder_rne(dut):
    table_path = "results_table.log"
    csv_path   = "results.csv"
    tf = open(table_path, "w", encoding="utf-8")
    cf = open(csv_path, "w", newline="", encoding="utf-8")
    cw = csv.writer(cf)

    header = (
        "rm | A_hex | A_dec | A_fields || B_hex | B_dec | B_fields || "
        "Out_hex | Out_dec | Out_fields | Ref_hex | Ref_dec | Ref_fields | RESULT"
    )
    tf.write(header + "\n")
    tf.write("-" * len(header) + "\n")
    cw.writerow([
        "rm",
        "A_hex","A_dec","A_sign","A_exp","A_man",
        "B_hex","B_dec","B_sign","B_exp","B_man",
        "Out_hex","Out_dec","Out_sign","Out_exp","Out_man",
        "Ref_hex","Ref_dec","Ref_sign","Ref_exp","Ref_man",
        "Result"
    ])

    failures = []
    for rm, a_hex, b_hex in VECTORS:
        dut.rm.value = rm
        dut.A.value  = int(a_hex, 16)
        dut.B.value  = int(b_hex, 16)
        await Timer(1, unit="ns")  # settle

        out_bits = int(dut.Out.value)
        out_f32  = f32_from_bits(out_bits)

        if rm == 0:
            a_f32 = f32_from_hex(a_hex)
            b_f32 = f32_from_hex(b_hex)
            ref_bits = bits_from_f32(np.float32(a_f32 + b_f32))
            ref_f32  = f32_from_bits(ref_bits)
            ok = same_fp32_bits(ref_bits, out_bits)
            result = "PASS" if ok else "FAIL"
            if not ok:
                failures.append(
                    f"rm=000 A={a_hex} B={b_hex} Expected={hex_from_bits(ref_bits)} Got={hex_from_bits(out_bits)}"
                )
            ref_hex_s = hex_from_bits(ref_bits)
            ref_dec_s = f32_dec_str(ref_f32)
            ref_fields_s = fmt_fields(ref_bits)
            Ref_s,Ref_e,Ref_m = split_fields(ref_bits)
        else:
            ref_bits = 0
            ref_hex_s = "N/A"
            ref_dec_s = "N/A"
            ref_fields_s = "N/A"
            Ref_s,Ref_e,Ref_m = (0,0,0)
            result = "SKIP"

        # human-readable row
        row_text = (
            f"{rm:03b} | {a_hex:>10} | {f32_dec_str(f32_from_hex(a_hex)):>18} | {fmt_fields(int(a_hex,16)):>24} || "
            f"{b_hex:>10} | {f32_dec_str(f32_from_hex(b_hex)):>18} | {fmt_fields(int(b_hex,16)):>24} || "
            f"{hex_from_bits(out_bits):>10} | {f32_dec_str(out_f32):>18} | {fmt_fields(out_bits):>24} | "
            f"{ref_hex_s:>10} | {ref_dec_s:>18} | {ref_fields_s:>24} | {result}"
        )
        tf.write(row_text + "\n")

        # CSV row
        A_s,A_e,A_m = split_fields(int(a_hex,16))
        B_s,B_e,B_m = split_fields(int(b_hex,16))
        O_s,O_e,O_m = split_fields(out_bits)
        cw.writerow([
            f"{rm:03b}",
            a_hex, f32_dec_str(f32_from_hex(a_hex)), f"0x{A_s:X}", f"0x{A_e:02X}", f"0x{A_m:06X}",
            b_hex, f32_dec_str(f32_from_hex(b_hex)), f"0x{B_s:X}", f"0x{B_e:02X}", f"0x{B_m:06X}",
            hex_from_bits(out_bits), f32_dec_str(out_f32), f"0x{O_s:X}", f"0x{O_e:02X}", f"0x{O_m:06X}",
            ref_hex_s, ref_dec_s, (f"0x{Ref_s:X}" if rm==0 else "N/A"),
            (f"0x{Ref_e:02X}" if rm==0 else "N/A"),
            (f"0x{Ref_m:06X}" if rm==0 else "N/A"),
            result
        ])

    tf.close(); cf.close()
    dut._log.info(f"Wrote human-readable log: {table_path}")
    dut._log.info(f"Wrote CSV: {csv_path}")

    if failures:
        raise AssertionError("Mismatches:\n  " + "\n  ".join(failures))
