#!/usr/bin/env python3
"""
fsm_diagram.py — Extract and draw FSMs from Verilog; label every transition.

- Supports states via typedef enum or parameter/localparam.
- Parses case(state) with nested if/else/begin/end.
- Labels:
    * conditional: full boolean expr (default) or just signals
    * else-if:  '!(prev_conds) & (this_cond)'
    * else:     '!(prev_conds)'
    * default arm: 'default'
    * truly unconditional: 'true'
- Outputs DOT and (if Graphviz is installed) SVG.
- Readability knobs: wrap, rankdir, fontsize, nodesep, ranksep, splines, concentrate.
- Self-tests include your PROGRAM block pattern.

Usage:
  python3 fsm_diagram.py --verilog core_controller_fsm.v -o out/core --wrap 18
  python3 fsm_diagram.py --label signals --wrap 18         # if you insist
  python3 fsm_diagram.py --selftest
"""

import argparse, re, sys, textwrap, shutil, subprocess
from pathlib import Path

# ---------- Utils ----------

def read_text(p: Path) -> str:
    return Path(p).read_text(encoding="utf-8", errors="ignore")

def strip_comments(s: str) -> str:
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    s = re.sub(r"//.*?$",   "", s, flags=re.M)
    return s

def uniq_stable(seq):
    seen=set(); out=[]
    for x in seq:
        if x not in seen:
            seen.add(x); out.append(x)
    return out

# ---------- State discovery ----------

RE_ENUM = re.compile(r"typedef\s+enum(?:\s+\w+)?\s*[^}]*\{(?P<body>[^}]*)\}\s*\w+\s*;", re.S|re.I)
RE_PARAM_ENUM = re.compile(
    r"\b(localparam|parameter)\b\s*(?:\[[^\]]+\]\s*)?"
    r"(?P<body>(?:[A-Za-z_]\w*\s*=\s*[^,;]+)(?:\s*,\s*[A-Za-z_]\w*\s*=\s*[^,;]+)*)\s*;",
    re.I|re.S)

IDENT = re.compile(r"[A-Za-z_]\w*")
KW = {"if","else","begin","end","case","casex","casez","default",
      "next_state","state","assign","module","endmodule"}

def parse_states(txt: str):
    states = set()
    for m in RE_ENUM.finditer(txt):
        for tok in m.group("body").split(","):
            name = tok.split("=")[0].strip()
            if re.match(r"^[A-Za-z_]\w*$", name): states.add(name)
    for m in RE_PARAM_ENUM.finditer(txt):
        for tok in m.group("body").split(","):
            name = tok.split("=")[0].strip()
            if re.match(r"^[A-Za-z_]\w*$", name): states.add(name)
    states.discard("default")
    return states

# ---------- Case parsing and transitions ----------

CASE_RE = re.compile(r"\bcase[zx]?\s*\(\s*(?P<var>[A-Za-z_]\w*)\s*\)(?P<body>.*?)endcase", re.S|re.I)

def normalize_case_body(body: str) -> str:
    # Make control tokens standalone so 'end else if (...)' becomes multiple lines.
    s = body
    s = re.sub(r"\bend\s+(?=else\b)", "end\n", s)
    s = re.sub(r"(?<!\n)\s+(else\s+if\b)", r"\n\1", s)
    s = re.sub(r"(?<!\n)\s+(else\b)", r"\n\1", s)
    s = re.sub(r"\s+([A-Za-z_]\w*\s*:)", r"\n\1", s)
    s = re.sub(r"\s+(default\s*:)", r"\n\1", s, flags=re.I)
    s = re.sub(r";\s*(?=[^;\n])", ";\n", s)
    return s

def extract_signals(expr: str, known_states):
    # Tokens without keywords/state names; keeps duplicates out but not negations.
    ids = []
    for tok in IDENT.findall(expr):
        if tok in KW or tok in known_states: continue
        if tok.lower() in {"and","or","not"}: continue
        ids.append(tok)
    return uniq_stable(ids)

def wrap_label(text: str, width: int) -> str:
    if width <= 0: return text
    cleaned = re.sub(r"\s+", " ", text.strip())
    if not cleaned: return cleaned
    cleaned = cleaned.replace("&", " & ").replace("|", " | ")
    return "\n".join(textwrap.wrap(cleaned, width=width, break_long_words=False, break_on_hyphens=False))

def disjoin(items):
    # "A | B | C"
    return " | ".join([f"({c})" if (" " in c or "&" in c or "|" in c) else c for c in items]) if items else ""

def parse_case_transitions(txt: str, known_states, label_mode: str):
    """
    Return list of (case_var, src_state_or_default, dst_state, label).
    Uses an if-chain tracker so else/else-if are labeled with complements.
    """
    results = []
    for m in CASE_RE.finditer(txt):
        case_var = m.group("var")
        body = normalize_case_body(m.group("body"))
        lines = [ln.strip() for ln in body.splitlines() if ln.strip()]
        cur_state = None
        in_default = False

        cond_stack = []      # active nested conditions (strings)
        block_stack = []     # "if","else","begin"
        chain_stack = []     # stack of lists: each list is prior conds in the current if/elseif/else chain

        for ln in lines:
            # New case item
            lab = re.match(r"^([A-Za-z_]\w*|default)\s*:\s*(?:begin\b)?", ln, re.I)
            if lab:
                tag = lab.group(1)
                in_default = (tag.lower() == "default")
                cur_state = None if in_default else tag
                cond_stack.clear(); block_stack.clear(); chain_stack.clear()
                continue

            if (cur_state is None) and (not in_default):
                continue

            # Control tracking
            m_if  = re.match(r"^if\s*\((?P<cond>[^)]*)\)\s*(?:begin\b)?", ln)
            m_eif = re.match(r"^else\s+if\s*\((?P<cond>[^)]*)\)\s*(?:begin\b)?", ln)
            m_el  = re.match(r"^else\b\s*(?:begin\b)?", ln)

            if m_if:
                raw = m_if.group("cond").strip()
                # start a new if-chain
                chain_stack.append([raw])
                cond_stack.append(raw); block_stack.append("if")
                continue

            if m_eif:
                raw = m_eif.group("cond").strip()
                if chain_stack:
                    prev = chain_stack[-1]
                    neg_prev = f"!({disjoin(prev)})" if prev else "true"
                    eff = f"{neg_prev} & ({raw})" if prev else raw
                    prev.append(raw)  # extend chain with this condition
                    # replace current chain condition on cond_stack if present, else push
                    if cond_stack:
                        cond_stack[-1] = eff
                    else:
                        cond_stack.append(eff)
                    # mark we're still in the same if/else chain
                    if block_stack:
                        block_stack[-1] = "if"
                    else:
                        block_stack.append("if")
                else:
                    # shouldn't happen, treat as plain if
                    cond_stack.append(raw); block_stack.append("if"); chain_stack.append([raw])
                continue

            if m_el:
                if chain_stack:
                    prev = chain_stack[-1]
                    eff = f"!({disjoin(prev)})" if prev else "true"
                    # replace or push active condition with else-effective expression
                    if cond_stack:
                        cond_stack[-1] = eff
                    else:
                        cond_stack.append(eff)
                    # tag as else to pop correctly later
                    if block_stack:
                        block_stack[-1] = "else"
                    else:
                        block_stack.append("else")
                    # no new condition added to prev list
                else:
                    # else without known chain: treat as unconditional true
                    if cond_stack:
                        cond_stack[-1] = "true"
                    else:
                        cond_stack.append("true")
                    block_stack.append("else")
                continue

            if re.match(r"^begin\b", ln): block_stack.append("begin"); continue

            if re.match(r"^end\b", ln):
                if block_stack:
                    kind = block_stack.pop()
                    if kind in ("if","else"):
                        if cond_stack: cond_stack.pop()
                        # do not pop chain_stack here; chain may continue with else/else-if
                continue

            # Transition
            m_ns = re.search(r"\bnext_state\s*(?:<=|=)\s*([A-Za-z_]\w*)\s*;", ln)
            if m_ns:
                dst = m_ns.group(1)
                if cond_stack:
                    expr = " & ".join([c for c in cond_stack if c])
                else:
                    expr = "default" if in_default else "true"
                label = expr
                if label_mode == "signals" and expr not in ("true","default"):
                    sigs = extract_signals(expr, known_states)
                    label = ", ".join(sigs) if sigs else expr
                src = cur_state if cur_state is not None else "default"
                results.append((case_var, src, dst, label))
                continue

    return results

# ---------- Graph output ----------

def to_dot(states, transitions, title="FSM", wrap=0,
           rankdir="LR", fontsize=12, nodesep=0.7, ranksep=0.8,
           splines="spline", concentrate="false", default_node_shape="diamond"):
    nodes = set(states)
    for _, s, d, _ in transitions:
        if s != "default": nodes.add(s)
        nodes.add(d)

    def fmt_label(s):
        return wrap_label(s, wrap) if wrap else s

    lines = []
    lines.append("digraph FSM {")
    lines.append(f'  rankdir={rankdir};')
    lines.append(f'  node [shape=circle, fontsize={fontsize}];')
    lines.append(f'  edge [fontsize={fontsize}];')
    lines.append(f'  graph [labelloc="t", label="{title}", fontsize={fontsize+2}, nodesep={nodesep}, ranksep={ranksep}, splines={splines}, concentrate={concentrate}];')

    default_used = any(s == "default" for _, s, _, _ in transitions)
    if default_used:
        lines.append(f'  "default" [shape={default_node_shape}, style=rounded, fontsize={fontsize}];')

    for n in sorted(nodes):
        if n == "default": continue
        lines.append(f'  "{n}";')

    by_var = {}
    for cv, s, d, l in transitions:
        by_var.setdefault(cv, []).append((s, d, l))

    for idx, (cv, edges) in enumerate(by_var.items(), 1):
        lines.append(f'  subgraph cluster_{idx} {{')
        lines.append(f'    label="{cv}"; labelloc="b"; fontsize={fontsize}; style=dashed; color=gray;')
        for s, d, lbl in edges:
            lab = fmt_label(lbl).replace('"','\\"')
            lines.append(f'    "{s}" -> "{d}" [label="{lab}"];')
        lines.append('  }')

    lines.append("}")
    return "\n".join(lines)

def render_svg(dot_path: Path, svg_path: Path) -> bool:
    if not shutil.which("dot"): return False
    subprocess.check_call(["dot", "-Tsvg", str(dot_path), "-o", str(svg_path)])
    return True

# ---------- Self tests ----------

SELFTEST_PROGRAM = r"""
module m(input clk);
  localparam [2:0] PROGRAM=3'b001, PARTIAL_IRQ=3'b010, FULL_FLUSH_RESET=3'b100, DONE=3'b101;
  reg [2:0] state, next_state;
  wire reset_request, initate_irq, end_condition;
  always @* begin
    next_state = state;
    case (state)
      PROGRAM: begin
        if (reset_request) begin
          next_state = FULL_FLUSH_RESET;
        end else if (initate_irq) begin
          next_state = PARTIAL_IRQ;
        end else if (end_condition) begin
          next_state = DONE;
        end
      end
      default: next_state = PROGRAM;
    endcase
  end
endmodule
"""

def run_selftests(args):
    outdir = Path("selftest_out"); outdir.mkdir(exist_ok=True)
    txt = strip_comments(SELFTEST_PROGRAM)
    states = parse_states(txt)
    trans  = parse_case_transitions(txt, states, args.label)
    # Edge labels should include complements, not "true"
    labels = sorted(set(l for _,_,_,l in trans))
    print("[selftest] labels:", labels)
    # sanity: expect reset_request, '!(reset_request) & (initate_irq)', '!(reset_request | initate_irq) & (end_condition)', and 'default'
    expect = {"reset_request",
              "!(reset_request) & (initate_irq)",
              "!( (reset_request) | (initate_irq) ) & (end_condition)".replace("  "," "),
              "!(reset_request | initate_irq) & (end_condition)",  # acceptable simplified form
              "default"}
    if args.label == "cond":
        if not any("reset_request" in l and "&" not in l and "!" not in l for l in labels):
            print("[FAIL] missing direct 'reset_request' edge"); sys.exit(1)
        if not any("initate_irq" in l and "!" in l for l in labels):
            print("[FAIL] missing complemented else-if edge"); sys.exit(1)
        if not any("end_condition" in l and "!" in l for l in labels):
            print("[FAIL] missing complemented else edge"); sys.exit(1)
    dot = to_dot(states, trans, title="program_block", wrap=args.wrap,
                 rankdir=args.rankdir, fontsize=args.fontsize,
                 nodesep=args.nodesep, ranksep=args.ranksep,
                 splines=args.splines, concentrate=args.concentrate)
    dot_path = outdir / "program_block.dot"
    dot_path.write_text(dot, encoding="utf-8")
    if shutil.which("dot"):
        render_svg(dot_path, outdir / "program_block.svg")
    print(f"[OK] selftest -> {dot_path}")

# ---------- CLI ----------

def main():
    ap = argparse.ArgumentParser(description="FSM diagrammer with labeled transitions (else shows complement)")
    ap.add_argument("--verilog", help="Verilog file to parse")
    ap.add_argument("-o", "--out", default="fsm_out/fsm", help="Output base path (no extension)")
    ap.add_argument("--title", default="main", help="Diagram title")
    ap.add_argument("--label", choices=["cond","signals"], default="cond",
                    help="Edge labels: full condition or only signal names")
    ap.add_argument("--wrap", type=int, default=18, help="Wrap labels at N chars (0 disables)")
    ap.add_argument("--rankdir", choices=["LR","TB","BT","RL"], default="LR")
    ap.add_argument("--fontsize", type=int, default=12)
    ap.add_argument("--nodesep", type=float, default=0.7)
    ap.add_argument("--ranksep", type=float, default=0.8)
    ap.add_argument("--splines", choices=["true","false","curved","polyline","spline"], default="spline")
    ap.add_argument("--concentrate", choices=["true","false"], default="false")
    ap.add_argument("--selftest", action="store_true", help="Run built-in test and emit example DOT/SVG")
    args = ap.parse_args()

    if args.selftest:
        run_selftests(args); return

    if not args.verilog:
        print("Provide --verilog FILE or use --selftest", file=sys.stderr)
        sys.exit(2)

    txt = strip_comments(read_text(Path(args.verilog)))
    states = parse_states(txt)
    transitions = parse_case_transitions(txt, states, args.label)

    if not transitions:
        print("No transitions found. Expect: case(state) ... next_state = STATE;", file=sys.stderr)
        sys.exit(1)
    if not states:
        inferred = set()
        for _, s, d, _ in transitions:
            if s != "default": inferred.add(s)
            inferred.add(d)
        states = inferred

    dot = to_dot(states, transitions, title=args.title, wrap=args.wrap,
                 rankdir=args.rankdir, fontsize=args.fontsize,
                 nodesep=args.nodesep, ranksep=args.ranksep,
                 splines=args.splines, concentrate=args.concentrate)

    base = Path(args.out); base.parent.mkdir(parents=True, exist_ok=True)
    dot_path = base.with_suffix(".dot"); dot_path.write_text(dot, encoding="utf-8")
    print(f"Wrote DOT: {dot_path}")

    if shutil.which("dot"):
        svg_path = base.with_suffix(".svg")
        try:
            render_svg(dot_path, svg_path)
            print(f"Wrote SVG: {svg_path}")
        except subprocess.CalledProcessError as e:
            print(f"Graphviz error: {e}", file=sys.stderr)
    else:
        print("Graphviz 'dot' not found; install it for SVG (apt/brew).")

if __name__ == "__main__":
    main()
