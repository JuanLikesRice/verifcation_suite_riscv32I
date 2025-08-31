# FSM Diagrammer

Generate state-machine diagrams from Verilog. The tool parses `case(state)` blocks, extracts transitions, and labels every edge with the condition that causes it. Output is Graphviz DOT (always) and SVG (if Graphviz is installed).

## Highlights
- Supports states declared as `typedef enum {...}` or `parameter/localparam`.
- Understands nested `if / else if / else` inside each case item.
- **Every arrow is labeled**:
  - Conditional edges use the active condition.
  - `else if (B)` labels as `!(A | …) & (B)` (complement of prior conditions AND the new one).
  - `else` labels as `!(A | …)` (complement of all prior conditions in the chain).
  - `default:` case arm is labeled `default`.
  - Truly unconditional edges are labeled `true`.
- Groups multiple FSMs (multiple `case(<var>)`) into subgraphs for readability.
- Label wrapping and layout controls for legible diagrams.
- Built-in self-tests verify labeling and emit example diagrams.

## Requirements
- Python 3.8+
- Optional: Graphviz (`dot`) for SVG rendering  
  - Ubuntu/Debian: `sudo apt install graphviz`  
  - macOS (Homebrew): `brew install graphviz`  
  - Windows: install Graphviz and add `dot` to PATH.

## Quick Start
```bash
python3 fsm_diagram.py --verilog core_controller_fsm.v   -o out/core_fsm --title "Core Controller" --wrap 18
```
Outputs:
- `out/core_fsm.dot` (always)
- `out/core_fsm.svg` (if `dot` available)

## CLI
```
usage: fsm_diagram.py --verilog FILE [-o OUT] [--title TITLE]
                      [--label {cond,signals}] [--wrap N]
                      [--rankdir {LR,TB,BT,RL}] [--fontsize N]
                      [--nodesep F] [--ranksep F]
                      [--splines {true,false,curved,polyline,spline}]
                      [--concentrate {true,false}] [--selftest]
```
- `--verilog FILE` Verilog source to parse.  
- `-o OUT` Output base path (no extension). Default: `fsm_out/fsm`.  
- `--title TITLE` Diagram title. Default: `main`.  
- `--label cond|signals` Edge label content.  
  - `cond` (default): full boolean expression as parsed.  
  - `signals`: only identifiers referenced in the condition.  
- `--wrap N` Wrap labels at N characters per line (0 disables). Default: `18`.  
- Layout: `--rankdir`, `--fontsize`, `--nodesep`, `--ranksep`, `--splines`, `--concentrate`.  
- `--selftest` Run built-in tests and emit example DOT/SVG under `selftest_out/`.

## What Gets Parsed
- **States**
  - `typedef enum logic [..] {IDLE=0, RUN=1, ...} state_t;`
  - `localparam/parameter [..] IDLE=..., RUN=..., ...;`
- **Transitions**
  - Inside a `case (state)` (or `casez/casex`) body:
    - Assignments `next_state = SOME_STATE;` or `next_state <= SOME_STATE;`
    - Optional surrounding `begin/end` and nested `if / else if / else`.
  - Source state is the case label (e.g., `IDLE:`, `RUN:`). Destination is taken from the assignment.
- Comments are ignored. `default:` is treated as a pseudo-source; it won’t create a node but edges from it are labeled `default`.

## Labeling Rules
Given:
```verilog
STATE_X: begin
  if (A)         next_state = S1;
  else if (B)    next_state = S2;
  else if (C)    next_state = S3;
  else           next_state = S4;
end
```
Edges and labels:
- `STATE_X → S1` : `A`
- `STATE_X → S2` : `!(A) & (B)`
- `STATE_X → S3` : `!(A | B) & (C)`
- `STATE_X → S4` : `!(A | B | C)`
If `--label signals` is used, labels simplify to identifiers involved (e.g., `A`, `B`, `C`).

For a `default:` arm:
```verilog
default: next_state = RESET;
```
Edge label: `default`.

If there is no condition within the case item (straight assignment), the edge label is `true`.

## Example
```verilog
localparam [2:0] IDLE=0, PROGRAM=1, PARTIAL_IRQ=2, IRQ_HANDLE=3, FULL_FLUSH_RESET=4, DONE=5;
always @* begin
  next_state = state;
  case (state)
    PROGRAM: begin
      if (reset_request)        next_state = FULL_FLUSH_RESET;
      else if (initate_irq)     next_state = PARTIAL_IRQ;
      else if (end_condition)   next_state = DONE;
    end
    default: next_state = IDLE;
  endcase
end
```
Generated edges:
- `PROGRAM → FULL_FLUSH_RESET` label: `reset_request`
- `PROGRAM → PARTIAL_IRQ` label: `!(reset_request) & (initate_irq)`
- `PROGRAM → DONE` label: `!(reset_request | initate_irq) & (end_condition)`
- `default → IDLE` label: `default`

## Readability Tips
- `--wrap 16` or `--wrap 20` keeps long labels from stretching.
- Increase spacing for dense graphs: `--nodesep 1.0 --ranksep 1.1`.
- Top-down layout for tall chains: `--rankdir TB`.
- If many parallel edges clutter the diagram, try `--concentrate true`.

## Self-Test
Run built-in tests to verify labeling and generate sample diagrams:
```bash
python3 fsm_diagram.py --selftest
```
Artifacts are written to `selftest_out/`. The script fails if any unlabeled edge is produced.

## Limitations
- Pragmatic parser, not a full Verilog/SystemVerilog front-end.
- Assumes a `case (state)` style FSM and `next_state` assignment.
- Macro-heavy or unconventional formatting may need minor cleanups.
- Multi-module files are supported; all `case(...)` blocks are graphed. For per-module images, run per file or post-filter.

## Troubleshooting
- **No transitions found**: Ensure your FSM uses `case(state)` and assigns `next_state = SOME_STATE;`.
- **Edge labeled `true` but you expect a condition**: Confirm the assignment is actually inside an `if/else` block.
- **`default` node appears**: Indicates transitions originating in a `default:` arm; expected behavior.
- **No SVG**: Install Graphviz (`dot`) and ensure it’s on PATH.

## License
Use freely for projects and research. Attribution appreciated.
