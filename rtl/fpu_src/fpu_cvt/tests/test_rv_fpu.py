# Cocotb test for unified rv_FPU: ADD and MUL now, extensible later.
# Handshake:
#   - Present inputs and assert req_valid_i.
#   - Request is TAKEN if req_taken_o==1 in that cycle.
#   - Results retire in-order when valid_out_ov==1.

import os, csv, random, subprocess, collections
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

# ---------------- timeouts (cycles) ----------------
# default 30; override with env if you want
ISSUE_TIMEOUT_CYCLES  = int(os.getenv("ISSUE_TIMEOUT_CYCLES",  "30"))
RETIRE_TIMEOUT_CYCLES = int(os.getenv("RETIRE_TIMEOUT_CYCLES", "30"))

# ---------------- opcodes (7-bit funct7-style) ----------------
# These match standard RV32F funct7 for single-precision:
OP_FADD_S = 0b0000000  # 0x00
OP_FMUL_S = 0b0001000  # 0x08
# Reserve more (e.g., OP_FSUB_S=0b0000100, OP_FDIV_S=0b0001100, OP_FMA_S uses rs3 path)

# ---------------- RM set selection ----------------
# Override via env: RM_SET="0,1,2,3,4,7"
# 0..4 are IEEE-754 modes; 7 means "use CSR rm" (dynamic).
RM_SET = [int(x) for x in os.getenv("RM_SET", "0,1,2,3,4,7").split(",")]

# ---------------- SoftFloat CLIs ------------------
_CLI_ADD = os.path.normpath(os.getenv(
    "SOFTFLOAT_CLI",
    os.path.join(os.path.dirname(__file__), "..", "build", "rv_softfloat_cli")
))
_CLI_MUL = os.path.normpath(os.getenv(
    "SOFTFLOAT_CLI_MUL",
    os.path.join(os.path.dirname(__file__), "..", "build", "rv_softfloat_cli_mul")
))

def oracle_add(a_bits:int, b_bits:int, rm:int) -> tuple[int,int]:
    p = subprocess.run([_CLI_ADD, str(rm), f"0x{a_bits:08X}", f"0x{b_bits:08X}"],
                       check=True, capture_output=True, text=True)
    res, flags = p.stdout.strip().split()
    return int(res,16), int(flags,16)

def oracle_mul(a_bits:int, b_bits:int, rm:int) -> tuple[int,int]:
    p = subprocess.run([_CLI_MUL, str(rm), f"0x{a_bits:08X}", f"0x{b_bits:08X}"],
                       check=True, capture_output=True, text=True)
    res, flags = p.stdout.strip().split()
    return int(res,16), int(flags,16)

# ---------------- helpers -------------------------
def hex_from_bits(u:int)->str: return f"0x{u & 0xFFFFFFFF:08X}"
def split_fields(u:int): return (u>>31)&1, (u>>23)&0xFF, u & 0x7FFFFF
def fmt_fields(u:int)->str:
    s,e,m = split_fields(u)
    return f"s=0x{s:X} e=0x{e:02X} m=0x{m:06X}"

def same_fp32_bits(exp_bits:int, got_bits:int)->bool:
    # +0 == -0; any NaN == any NaN
    if (exp_bits & 0x7FFFFFFF)==0 and (got_bits & 0x7FFFFFFF)==0:
        return True
    is_nan = lambda v: (v & 0x7F800000)==0x7F800000 and (v & 0x007FFFFF)!=0
    return exp_bits==got_bits or (is_nan(exp_bits) and is_nan(got_bits))

def canon_nan_f32(u:int)->int:
    if (u & 0x7F800000)==0x7F800000 and (u & 0x007FFFFF)!=0:
        return 0x7FC00000
    return u

def eff_rm(instr_rm:int, csr_rm:int)->int:
    # Use instr rm if <5; else take CSR rm (masked to 3 bits)
    return instr_rm if instr_rm < 5 else (csr_rm & 0x7)

# ---------------- vectors -------------------------
def _expand_edges_with_rm(edges_base, rm_list):
    """
    edges_base: list of (op7, A_hex, B_hex, RS3_hex)
    returns   : list of (op7, rm, A_hex, B_hex, RS3_hex)
    """
    out=[]
    for op7, a_hex, b_hex, r3_hex in edges_base:
        for rm in rm_list:
            out.append((op7, rm, a_hex, b_hex, r3_hex))
    return out

def mk_edge_vectors():
    # Your four seeds, now with RS3 and RM expansion.
    edges_base = [
        (OP_FADD_S, "0x7F800000", "0xFF800000", "0x00000000"),  # +inf + -inf
        (OP_FADD_S, "0x3FA00000", "0x3FB00000", "0x00000000"),  # 1.25 + 1.375
        (OP_FMUL_S, "0x3F800000", "0x00000000", "0x00000000"),  # 1.0 * 0.0
        (OP_FMUL_S, "0x7FC00001", "0x40000000", "0x00000000"),  # qNaN * 2.0
    ]
    return _expand_edges_with_rm(edges_base, RM_SET)

def mk_random_vectors(n:int=400, seed:int=2025):
    rng=random.Random(seed)
    def hx(u): return f"0x{u & 0xFFFFFFFF:08X}"
    def norm(): return ((rng.getrandbits(1)<<31)|((rng.randrange(1,255)&0xFF)<<23)|(rng.getrandbits(23)))
    def subn(): return ((rng.getrandbits(1)<<31)|(0<<23)|(rng.randrange(1,1<<23)))
    out=[]
    for _ in range(n):
        op7 = OP_FADD_S if rng.random()<0.5 else OP_FMUL_S
        a = norm() if rng.random()>0.2 else subn()
        b = norm() if rng.random()>0.2 else subn()
        r3 = 0
        rm = random.choice(RM_SET)
        out.append((op7, rm, hx(a), hx(b), hx(r3)))
    rng.shuffle(out)
    return out

# ---------------- pretty print --------------------
W_OP,W_RM,W_HEX,W_FIELDS,W_RESULT = 7,3,10,24,6
def header_line():
    h=(f"{'op7':>{W_OP}} | {'rm':>{W_RM}} | "
       f"{'A_hex':>{W_HEX}} | {'A_fields':>{W_FIELDS}} || "
       f"{'B_hex':>{W_HEX}} | {'B_fields':>{W_FIELDS}} || "
       f"{'RS3_hex':>{W_HEX}} || "
       f"{'Out_hex':>{W_HEX}} | {'Out_fields':>{W_FIELDS}} | "
       f"{'Ref_hex':>{W_HEX}} | {'Ref_fields':>{W_FIELDS}} | "
       f"{'RESULT':>{W_RESULT}}")
    return h, "-"*len(h)

def row_line(op7,rm,a_hex,b_hex,r3_hex,out_bits,ref_bits,result):
    return (f"{op7:0{W_OP}b} | {rm:0{W_RM}b} | "
            f"{a_hex:>{W_HEX}} | {fmt_fields(int(a_hex,16)):>{W_FIELDS}} || "
            f"{b_hex:>{W_HEX}} | {fmt_fields(int(b_hex,16)):>{W_FIELDS}} || "
            f"{r3_hex:>{W_HEX}} || "
            f"{hex_from_bits(out_bits):>{W_HEX}} | {fmt_fields(out_bits):>{W_FIELDS}} | "
            f"{hex_from_bits(ref_bits):>{W_HEX}} | {fmt_fields(ref_bits):>{W_FIELDS}} | "
            f"{result:>{W_RESULT}}")

# ---------------- handshake-aware issuer ----------
async def issue_when_taken(dut, op7:int, instr_rm:int, csr_rm:int, a_bits:int, b_bits:int, r3_bits:int):
    # Drive inputs and assert req_valid_i; hold until taken or timeout.
    dut.fp_instruction.value = op7
    dut.rm.value      = instr_rm
    dut.csr_rm.value  = csr_rm
    dut.rs1_data.value     = a_bits
    dut.rs2_data.value     = b_bits
    dut.rs3_data.value     = r3_bits
    dut.req_valid_i.value = 1

    cycles = 0
    while True:
        # small comb settle window
        for _ in range(2):
            await Timer(1, units="ps")
            if int(dut.req_taken_o.value):
                dut.req_valid_i.value = 0
                return
        await RisingEdge(dut.clk)
        cycles += 1
        if cycles >= ISSUE_TIMEOUT_CYCLES:
            dut.req_valid_i.value = 0
            raise AssertionError(
                f"Timeout waiting for req_taken_o after {ISSUE_TIMEOUT_CYCLES} cycles "
                f"(op7={op7:07b}, rm={instr_rm:03b}, csr_rm={csr_rm:03b}, "
                f"A=0x{a_bits:08X}, B=0x{b_bits:08X}, RS3=0x{r3_bits:08X})"
            )

# ---------------- main test -----------------------
@cocotb.test()
async def check_rv_fpu_add_mul(dut):
    # Clock + reset
    cocotb.start_soon(Clock(dut.clk, 5, units="ns").start())  # 100 MHz
    dut.rst.value=1
    dut.req_valid_i.value=0
    dut.rm.value=0
    dut.csr_rm.value=0
    dut.rs1_data.value=0
    dut.rs2_data.value=0
    dut.rs3_data.value=0
    for _ in range(4): await RisingEdge(dut.clk)
    dut.rst.value=0
    await RisingEdge(dut.clk)

    V = mk_edge_vectors() + mk_random_vectors(4, seed=31415)

    tf=open("results_table.log","w",encoding="utf-8")
    cf=open("results.csv","w",newline="",encoding="utf-8"); cw=csv.writer(cf)
    hdr,bar = header_line(); tf.write(hdr+"\n"); tf.write(bar+"\n")
    cw.writerow(["op7","rm","csr_rm","A_hex","B_hex","RS3_hex","Out_hex","Ref_hex","IEEE_Flags","Result"])

    q=collections.deque()
    failures=[]
    i=0
    drain=0
    MAX_DRAIN=4096  # keep as-is; we add explicit timeout below

    while (i < len(V)) or (q and drain < MAX_DRAIN):
        # Try to issue next request
        if i < len(V):
            op7, instr_rm, a_hex, b_hex, r3_hex = V[i]
            a_bits=int(a_hex,16); b_bits=int(b_hex,16); r3_bits=int(r3_hex,16)
            csr_rm = (i & 7)  # rotate CSR RM for dynamic-rm cases
            rm_eff = eff_rm(instr_rm, csr_rm)

            # Compute reference
            if op7 == OP_FADD_S:
                ref_bits, flags = oracle_add(a_bits, b_bits, rm_eff)
            elif op7 == OP_FMUL_S:
                ref_bits, flags = oracle_mul(a_bits, b_bits, rm_eff)
            else:
                raise RuntimeError("Unsupported op7 in vector set")
            ref_bits = canon_nan_f32(ref_bits)

            # Issue and record
            await issue_when_taken(dut, op7, instr_rm, csr_rm, a_bits, b_bits, r3_bits)
            q.append((op7, instr_rm, csr_rm, a_hex, b_hex, r3_hex, ref_bits, flags))
            i += 1
        else:
            await RisingEdge(dut.clk)

        # Retire on valid_out_ov
        await FallingEdge(dut.clk)
        if int(dut.valid_out_ov.value) and q:
            op7, instr_rm, csr_rm, a_hex, b_hex, r3_hex, ref_bits, flags = q.popleft()

            # X/Z-safe read
            await Timer(1, units="ps")
            try:
                out_bits = int(dut.result_s1.value) & 0xFFFFFFFF
            except Exception:
                await RisingEdge(dut.clk); await Timer(1,"ps")
                out_bits = int(dut.result_s1.value) & 0xFFFFFFFF

            ok = same_fp32_bits(ref_bits, out_bits)

            # Optional flags check if DUT exposes full fflags[4:0]
            if hasattr(dut,"fflags"):
                gotf = int(dut.fflags.value) & 0x1F
                ok = ok and (gotf == (flags & 0x1F))
                if gotf != (flags & 0x1F):
                    failures.append(f"fflags mismatch op7={op7:07b} A={a_hex} B={b_hex} exp=0x{flags & 0x1F:02X} got=0x{gotf:02X}")

            tf.write(row_line(op7, instr_rm, a_hex, b_hex, r3_hex, out_bits, ref_bits, "PASS" if ok else "FAIL") + "\n")
            cw.writerow([
                f"{op7:07b}", f"{instr_rm:03b}", f"{csr_rm:03b}",
                a_hex, b_hex, r3_hex, hex_from_bits(out_bits), hex_from_bits(ref_bits),
                f"0x{flags & 0x1F:02X}",
                "PASS" if ok else "FAIL"
            ])
            drain=0
        else:
            if i >= len(V):
                drain += 1
                if drain >= RETIRE_TIMEOUT_CYCLES and q:
                    # q not empty but no valid_out_ov for RETIRE_TIMEOUT_CYCLES
                    op7, instr_rm, csr_rm, a_hex, b_hex, r3_hex, _, _ = q[0]
                    raise AssertionError(
                        f"Timeout waiting for valid_out_ov after {RETIRE_TIMEOUT_CYCLES} cycles "
                        f"for oldest in-flight op7={op7:07b}, rm={instr_rm:03b}, csr_rm={csr_rm:03b}, "
                        f"A={a_hex}, B={b_hex}, RS3={r3_hex}"
                    )

    tf.close(); cf.close()
    dut._log.info("Wrote results_table.log and results.csv")

    if failures:
        raise AssertionError("Mismatches:\n  " + "\n  ".join(failures))
