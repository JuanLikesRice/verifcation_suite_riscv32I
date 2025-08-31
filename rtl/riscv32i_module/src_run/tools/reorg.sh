# reorg.sh
set -euo pipefail

TOP="riscv32i_main"                 # set your real top here
DEFINES=()                          # e.g., ("SYNTHESIS" "FPGA=1")
EXCLUDE_TB_GLOB="*TB.v"             # testbench filter

mkdir -p build
shopt -s nullglob

# 0) Optional formatting
if command -v verible-verilog-format >/dev/null 2>&1; then
  for f in *.v; do
    [[ "$f" == $EXCLUDE_TB_GLOB ]] && continue
    verible-verilog-format --inplace "$f"
  done
else
  echo "verible-verilog-format not found. Skipping formatting." >&2
fi

# 1) Include dirs from all .vh locations (plus project root)
INCLUDE_DIRS=(".")
while IFS= read -r d; do INCLUDE_DIRS+=("$d"); done < <(find . -type f -name "*.vh" -exec dirname {} \; | sort -u)

# 2) Collect header files explicitly (so macros like `inst_UNKNOWN are visible)
VH_FILES=$(ls *.vh 2>/dev/null || true)

# 3) Collect RTL files (exclude TBs)
READ_FILES=()
for f in *.v; do
  [[ "$f" == $EXCLUDE_TB_GLOB ]] && continue
  READ_FILES+=("$f")
done

# 4) Build yosys prelude (include paths + defines)
YOSYS_PRE=""
for d in "${INCLUDE_DIRS[@]}"; do YOSYS_PRE+="verilog_defaults -add -I $d; "; done
for def in "${DEFINES[@]}";     do YOSYS_PRE+="verilog_defaults -add -D $def; "; done

# 5) Yosys run
yosys -q -p "
$YOSYS_PRE
read_verilog -sv $VH_FILES ${READ_FILES[*]};
hierarchy -check -top $TOP;
write_verilog -noattr -norename build/combined.v;
write_json build/netlist.json;
show -format svg -prefix build/hier $TOP
"

echo "OK: build/combined.v  build/hier.svg"
