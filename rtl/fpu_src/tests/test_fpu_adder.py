import os, struct, csv, random, subprocess
import numpy as np, cocotb
from cocotb.triggers import Timer

# ---------- helpers ----------
def f32_from_bits(u: int) -> np.float32:
    return np.float32(struct.unpack(">f", (u & 0xFFFFFFFF).to_bytes(4, "big", signed=False))[0])
def bits_from_f32(x: float) -> int:
    b = struct.pack(">f", float(np.float32(x))); return int.from_bytes(b, "big", signed=False)
def f32_from_hex(h: str) -> np.float32: return f32_from_bits(int(h, 16))
def hex_from_bits(u: int) -> str: return f"0x{u & 0xFFFFFFFF:08X}"
def split_fields(u: int): return (u>>31)&1, (u>>23)&0xFF, u & 0x7FFFFF
def fmt_fields(u: int) -> str:
    s,e,m = split_fields(u); return f"s=0x{s:X} e=0x{e:02X} m=0x{m:06X}"
def same_fp32_bits(exp_bits: int, got_bits: int) -> bool:
    if (exp_bits & 0x7FFFFFFF) == 0 and (got_bits & 0x7FFFFFFF) == 0: return True
    def is_nan(u): return (u & 0x7F800000) == 0x7F800000 and (u & 0x007FFFFF) != 0
    if is_nan(exp_bits) and is_nan(got_bits): return True
    return exp_bits == got_bits
def f32_dec_str(x: float) -> str: return repr(float(np.float32(x)))

# ---------- vectors ----------
VECTORS = [
    (0b000,"0x3FA00000","0x3FB00000"),
    (0b000,"0x3FA00000","0x443BD800"),
    (0b000,"0x3FA00000","0x3FA00000"),
    (0b000,"0xBFC00000","0x3FA00000"),
    (0b000,"0x00000000","0x80000000"),
    (0b000,"0x3F800000","0x2F000000"),
    (0b000,"0x5F1B3E64","0x5F1B3E64"),
    (0b000,"0x7F800000","0x3F800000"),
    (0b000,"0x7FC00001","0x40000000"),
    (0b000,"0x00000080","0x3F000000"),
    (0b001,"0x3E99999A","0x3E99999A"),
    (0b010,"0x3E99999A","0x3E4CCCCD"),
    (0b011,"0x3F000000","0x00000001"),
    (0b100,"0x3F000000","0x3E800000"),
    (0b000,"0xC2480000","0x42480000"),
]

def gen_random_vectors(n: int = 200, seed: int = 123):
    rng = random.Random(seed); out = []
    def hx(u: int) -> str: return f"0x{u & 0xFFFFFFFF:08X}"
    def mk_norm(s,e,m): return ((s&1)<<31)|((e&0xFF)<<23)|(m&0x7FFFFF)
    def mk_sub(s,mnz): return ((s&1)<<31)|(0<<23)|(mnz&0x7FFFFF)
    def mk_inf(s): return ((s&1)<<31)|0x7F800000
    def mk_qnan(p=1): return 0x7FC00000 | (p & 0x003FFFFF)
    edges = [
        (0x00000000,0x00000000), (0x80000000,0x00000000),
        (mk_inf(0),mk_inf(1)), (mk_qnan(1),mk_norm(0,120,1)),
        (mk_sub(0,1),mk_norm(0,127,0)),
        (mk_norm(0,254,0x7FFFFF), mk_norm(0,254,0x7FFFFF)),
    ]
    for a,b in edges: out.append((0b000,hx(a),hx(b)))
    def rand_norm(): return mk_norm(rng.getrandbits(1), rng.randrange(1,255), rng.getrandbits(23))
    def rand_sub():  return mk_sub(rng.getrandbits(1), rng.randrange(1,1<<23))
    for _ in range(max(0,n-len(edges))):
        a,b = (rand_sub(),rand_norm()) if rng.random()<0.3 else (rand_norm(),rand_norm())
        out.append((rng.randrange(0,5), hx(a), hx(b)))
    rng.shuffle(out); return out

# ---------- pretty table ----------
W_RM,W_HEX,W_DEC,W_FIELDS,W_RESULT = 3,10,20,24,6
def header_line():
    h=(f"{'rm':>{W_RM}} | "
       f"{'A_hex':>{W_HEX}} | {'A_dec':>{W_DEC}} | {'A_fields':>{W_FIELDS}} || "
       f"{'B_hex':>{W_HEX}} | {'B_dec':>{W_DEC}} | {'B_fields':>{W_FIELDS}} || "
       f"{'Out_hex':>{W_HEX}} | {'Out_dec':>{W_DEC}} | {'Out_fields':>{W_FIELDS}} | "
       f"{'Ref_hex':>{W_HEX}} | {'Ref_dec':>{W_DEC}} | {'Ref_fields':>{W_FIELDS}} | "
       f"{'RESULT':>{W_RESULT}}")
    return h, "-"*len(h)
def row_line(rm,a_hex,b_hex,out_bits,ref_hex_s,ref_dec_s,ref_fields_s,result):
    a_dec=f32_dec_str(f32_from_hex(a_hex)); b_dec=f32_dec_str(f32_from_hex(b_hex))
    out_dec=f32_dec_str(f32_from_bits(out_bits))
    a_fields=fmt_fields(int(a_hex,16)); b_fields=fmt_fields(int(b_hex,16)); out_fields=fmt_fields(out_bits)
    return (f"{rm:0{W_RM}b} | {a_hex:>{W_HEX}} | {a_dec:>{W_DEC}} | {a_fields:>{W_FIELDS}} || "
            f"{b_hex:>{W_HEX}} | {b_dec:>{W_DEC}} | {b_fields:>{W_FIELDS}} || "
            f"{hex_from_bits(out_bits):>{W_HEX}} | {out_dec:>{W_DEC}} | {out_fields:>{W_FIELDS}} | "
            f"{ref_hex_s:>{W_HEX}} | {ref_dec_s:>{W_DEC}} | {ref_fields_s:>{W_FIELDS}} | "
            f"{result:>{W_RESULT}}")

# ---------- oracle via CLI ----------
# _CLI = os.path.join(os.path.dirname(__file__), "build", "rv_softfloat_cli")
_CLI = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "build", "rv_softfloat_cli"))

def softfloat_f32_add_bits(a_bits:int, b_bits:int, rm:int):
    if not os.path.exists(_CLI):
        raise RuntimeError(f"SoftFloat CLI not found at {_CLI}. Run: make cli")
    p = subprocess.run([_CLI, str(rm), f"0x{a_bits:08X}", f"0x{b_bits:08X}"],
                       check=True, capture_output=True, text=True)
    res, flags = p.stdout.strip().split()
    return int(res,16), int(flags,16)

# ---------- cocotb test ----------
@cocotb.test()
async def check_fpu_adder_riscv(dut):
    N_RANDOM, SEED = 300, 2025
    ALL_VECTORS = VECTORS + gen_random_vectors(N_RANDOM, seed=SEED)

    table_path, csv_path = "results_table.log", "results.csv"
    tf = open(table_path, "w", encoding="utf-8")
    cf = open(csv_path, "w", newline="", encoding="utf-8"); cw = csv.writer(cf)

    hdr, bar = header_line(); tf.write(hdr+"\n"); tf.write(bar+"\n")
    cw.writerow(["rm",
        "A_hex","A_dec","A_sign","A_exp","A_man",
        "B_hex","B_dec","B_sign","B_exp","B_man",
        "Out_hex","Out_dec","Out_sign","Out_exp","Out_man",
        "Ref_hex","Ref_dec","Ref_sign","Ref_exp","Ref_man",
        "IEEE_Flags","Result"])

    failures=[]
    for rm,a_hex,b_hex in ALL_VECTORS:
        a_bits=int(a_hex,16); b_bits=int(b_hex,16)

        dut.rm.value=rm; dut.A.value=a_bits; dut.B.value=b_bits
        await Timer(1, unit="ns")

        out_bits=int(dut.Out.value)

        if rm in (0,1,2,3,4):
            ref_bits, flags = softfloat_f32_add_bits(a_bits,b_bits,rm)
            ok = same_fp32_bits(ref_bits, out_bits)
            result = "PASS" if ok else "FAIL"
            if not ok:
                failures.append(f"rm={rm:03b} A={a_hex} B={b_hex} Expected={hex_from_bits(ref_bits)} Got={hex_from_bits(out_bits)}")
            ref_hex_s=hex_from_bits(ref_bits)
            ref_dec_s=f32_dec_str(f32_from_bits(ref_bits))
            ref_fields_s=fmt_fields(ref_bits)
            Ref_s,Ref_e,Ref_m = split_fields(ref_bits)
            flags_hex=f"0x{flags:02X}"
        else:
            ref_hex_s=ref_dec_s=ref_fields_s="N/A"; Ref_s=Ref_e=Ref_M=0
            flags_hex="N/A"; result="SKIP"

        tf.write(row_line(rm,a_hex,b_hex,out_bits,ref_hex_s,ref_dec_s,ref_fields_s,result)+"\n")

        A_s,A_e,A_m=split_fields(a_bits); B_s,B_e,B_m=split_fields(b_bits); O_s,O_e,O_m=split_fields(out_bits)
        cw.writerow([f"{rm:03b}",
            a_hex,f32_dec_str(f32_from_bits(a_bits)),f"0x{A_s:X}",f"0x{A_e:02X}",f"0x{A_m:06X}",
            b_hex,f32_dec_str(f32_from_bits(b_bits)),f"0x{B_s:X}",f"0x{B_e:02X}",f"0x{B_m:06X}",
            hex_from_bits(out_bits),f32_dec_str(f32_from_bits(out_bits)),f"0x{O_s:X}",f"0x{O_e:02X}",f"0x{O_m:06X}",
            ref_hex_s,ref_dec_s,f"0x{Ref_s:X}" if result!="SKIP" else "N/A",
            f"0x{Ref_e:02X}" if result!="SKIP" else "N/A",
            f"0x{Ref_m:06X}" if result!="SKIP" else "N/A",
            flags_hex,result])

    tf.close(); cf.close()
    dut._log.info(f"Wrote human-readable log: {table_path}")
    dut._log.info(f"Wrote CSV: {csv_path}")
    if failures:
        raise AssertionError("Mismatches:\n  " + "\n  ".join(failures))
