#!/usr/bin/env python3
"""
wire_consolidating.py — condense Verilog/SystemVerilog net declarations by width.

- Groups by (kind, signed, packed range text). Parameterized widths with the SAME TEXT
  (e.g. [N_param-1:0] vs [`size_X_LEN-1:0]) are separate groups.
- Supports wire|logic|tri|reg. Skips names with initializers or unpacked dims.
- Scopes:
    runs  : condense contiguous runs (separated only by whitespace/comments)  [default]
    file  : condense across entire file, insert grouped decls at the first decl position
- Debug: --debug prints what it found.

Usage:
  python3 wire_consolidating.py src.v --in-place
  python3 wire_consolidating.py src.v --scope file --in-place
  python3 wire_consolidating.py src.v --debug > /dev/null
"""

import re, sys, argparse
from pathlib import Path

RE_BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.S)
RE_LINE_COMMENT  = re.compile(r"//.*?$", re.M)
RE_NET_DECL = re.compile(r"""
    (?P<attr>\(\*\s*.*?\s*\*\)\s*)?                 # attributes
    \b(?P<kind>wire|logic|tri|reg)\b                # kind
    (?P<trailer>(?:\s+signed|\s+unsigned|\s+\[[^\]]+\])*)  # signed/range in any order
    \s+(?P<names>[^;]+?)\s*;                        # names
""", re.I | re.S | re.X)
IDENT_ONLY = re.compile(r"^[A-Za-z_]\w*$")

def strip_comments_keep_ws(s: str) -> str:
    s = RE_BLOCK_COMMENT.sub(lambda m: " " * (m.end()-m.start()), s)
    s = RE_LINE_COMMENT.sub("", s)
    return s

def normalize_range(trailer: str):
    signed = 1 if re.search(r"\bsigned\b", trailer or "", re.I) else 0
    m = re.search(r"\[([^\]]+)\]", trailer or "")
    if not m: return signed, "", ""
    inside = re.sub(r"\s+", "", m.group(1))
    return signed, inside, m.group(0)  # keep original "[...]" for re-emit

def split_simple_names(name_list: str):
    out = []
    for raw in name_list.split(","):
        tok = raw.strip()
        if not tok or "=" in tok or "[" in tok or "]" in tok:
            continue
        if IDENT_ONLY.match(tok):
            out.append(tok)
    return out

def width_numeric(range_key: str):
    m = re.fullmatch(r"(\d+):(\d+)", range_key)
    if not m: return None
    hi, lo = int(m.group(1)), int(m.group(2))
    return abs(hi - lo) + 1

def list_decl_matches(text: str, kinds: set[str]):
    matches = []
    for m in RE_NET_DECL.finditer(text):
        kind = m.group("kind").lower()
        if kind not in kinds: continue
        signed, rkey, rorig = normalize_range(m.group("trailer") or "")
        names = split_simple_names(m.group("names"))
        if not names: continue
        matches.append((m.span(), kind, signed, rkey, rorig, names))
    return matches

def make_groups(entries):
    groups = {}  # key=(kind,signed,range_key,range_orig)->set(names)
    for (_span, kind, signed, rk, ro, names) in entries:
        groups.setdefault((kind, signed, rk, ro), set()).update(names)
    return groups

def sort_groups(groups):
    def width_of(rk):
        w = width_numeric(rk)
        return (0, w) if w is not None else (1, 0)
    def keyfn(k):
        kind, signed, rk, _ro = k
        wclass, w = width_of(rk)
        return (wclass, w, rk, kind, signed)
    return sorted(groups.keys(), key=keyfn)

def emit_grouped(groups, indent=""):
    lines = []
    for (kind, signed, rk, ro) in sort_groups(groups):
        names = sorted(groups[(kind, signed, rk, ro)], key=str.lower)
        rng = (ro + " ") if rk else ""
        sgn = "signed " if signed else ""
        lines.append(f"{indent}{kind} {sgn}{rng}" + ", ".join(names) + ";")
    return "\n".join(lines)

def condense_runs(text: str, kinds: set[str], debug=False):
    matches = list_decl_matches(text, kinds)
    if not matches: return text, False
    nocom = strip_comments_keep_ws(text)

    # Build runs of adjacent matches (only whitespace/comments between)
    runs, cur = [], [matches[0]]
    for m in matches[1:]:
        prev_end = cur[-1][0][1]
        between = nocom[prev_end:m[0][0]]
        if between.strip() == "":
            cur.append(m)
        else:
            runs.append(cur); cur = [m]
    runs.append(cur)

    if debug:
        for i, run in enumerate(runs, 1):
            print(f"[DEBUG] run #{i} size={len(run)}", file=sys.stderr)
            for (_span, kind, signed, rk, ro, names) in run:
                print(f"  {kind} {'signed ' if signed else ''}[{rk or ''}] :: {', '.join(names)}", file=sys.stderr)

    out, last, changed = [], 0, False
    for run in runs:
        a, b = run[0][0][0], run[-1][0][1]
        out.append(text[last:a])
        groups = make_groups(run)
        # indent from first line
        line_start = text.rfind("\n", 0, a) + 1
        indent = re.match(r"[ \t]*", text[line_start:a]).group(0)
        repl = emit_grouped(groups, indent)
        out.append(repl)
        # detect real change
        orig_slice = text[a:b]
        if re.sub(r"\s+", " ", orig_slice.strip()) != re.sub(r"\s+", " ", repl.strip()):
            changed = True
        last = b
    out.append(text[last:])
    return "".join(out), changed

def condense_file_scope(text: str, kinds: set[str], debug=False):
    matches = list_decl_matches(text, kinds)
    if not matches: return text, False
    if debug:
        print(f"[DEBUG] file-scope matches: {len(matches)}", file=sys.stderr)
    groups = make_groups(matches)
    # delete all matched spans
    spans = [m[0] for m in matches]
    spans.sort()
    out, last = [], 0
    for a, b in spans:
        out.append(text[last:a]); last = b
    remainder = text[last:]
    # Insert grouped decls at first match position
    insert_at = spans[0][0]
    before = text[:insert_at]
    # indent from first line of first match
    line_start = text.rfind("\n", 0, insert_at) + 1
    indent = re.match(r"[ \t]*", text[line_start:insert_at]).group(0)
    decls = emit_grouped(groups, indent)
    new_text = before + decls + remainder
    # changed if decls count > 0
    return new_text, True

def enumerate_files(paths, recursive=False, exts=(".v",".sv")):
    files = []
    for p in paths:
        P = Path(p)
        if P.is_file() and P.suffix.lower() in exts:
            files.append(P)
        elif P.is_dir():
            it = P.rglob("*") if recursive else P.glob("*")
            files += [f for f in it if f.is_file() and f.suffix.lower() in exts]
        else:
            files += [f for f in Path().glob(p) if f.is_file() and f.suffix.lower() in exts]
    return sorted(set(files))

def main():
    ap = argparse.ArgumentParser(description="Condense net declarations by width.")
    ap.add_argument("paths", nargs="+", help="Files or directories")
    ap.add_argument("-r","--recursive", action="store_true", help="Recurse into directories")
    ap.add_argument("--ext", default=".v,.sv", help="Comma-separated extensions")
    ap.add_argument("--kinds", default="wire,logic,tri,reg", help="Kinds to include")
    ap.add_argument("--scope", choices=["runs","file"], default="runs", help="Condense per contiguous run or whole file")
    ap.add_argument("--in-place", action="store_true", help="Overwrite files")
    ap.add_argument("--debug", action="store_true", help="Print matched decls/groups to stderr")
    args = ap.parse_args()

    kinds = set(s.strip().lower() for s in args.kinds.split(",") if s.strip())
    exts = tuple(s.strip().lower() for s in args.ext.split(",") if s.strip().startswith("."))

    files = enumerate_files(args.paths, recursive=args.recursive, exts=exts)
    if not files:
        print("No matching files.", file=sys.stderr); sys.exit(2)

    changed_any = False
    for f in files:
        text = f.read_text(encoding="utf-8", errors="ignore")
        if args.scope == "file":
            new_text, changed = condense_file_scope(text, kinds, debug=args.debug)
        else:
            new_text, changed = condense_runs(text, kinds, debug=args.debug)
        changed_any |= changed
        if args.in_place:
            if changed:
                f.write_text(new_text, encoding="utf-8")
                print(f"[OK] condensed {f}")
            else:
                print(f"[SKIP] no condense {f}")
        else:
            sys.stdout.write(new_text)
    sys.exit(0 if (changed_any or not args.in_place) else 1)

if __name__ == "__main__":
    main()
