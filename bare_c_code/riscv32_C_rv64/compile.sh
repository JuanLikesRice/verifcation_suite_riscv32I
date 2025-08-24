#!/bin/bash
set -euo pipefail

# Toolchain/arch (override via env if needed: TARGET/MARCH/MABI)
TARGET="${TARGET:-riscv64-unknown-elf}"
MARCH="${MARCH:-rv64i_zicsr}"      # add m/a/c as you implement them (e.g., rv64imac_zicsr)
MABI="${MABI:-lp64}"

# Directories
INPUT_DIR="inputs"
COMPILATION_DIR="compilation"
VERILOG_DIR="verilog"

# Prep
mkdir -p "$COMPILATION_DIR" "$VERILOG_DIR"
rm -rf "$COMPILATION_DIR"/*

# Copy inputs
cp "$INPUT_DIR"/* "$COMPILATION_DIR"/

# Build
cd "$COMPILATION_DIR" || exit
echo "Compiling for RV64 ($MARCH, $MABI)..."

# C compile
$TARGET-gcc -march=$MARCH -mabi=$MABI -mcmodel=medany \
  -nostdlib -ffreestanding -O2 -c -o program.o program.c

# Startup (assembler)
$TARGET-as -march=$MARCH -o startup.o startup.S

# Link via GCC driver so libgcc is pulled correctly
$TARGET-gcc -march=$MARCH -mabi=$MABI -nostdlib \
  -Wl,-T,link.ld -Wl,-e,_start -o program.elf program.o startup.o

# Binary + introspection
$TARGET-objcopy -O binary program.elf program.bin
$TARGET-readelf -h program.elf

$TARGET-objdump -D -b binary -m riscv:rv64 program.bin > program_disassembly.txt
$TARGET-objdump -D program.elf > instructions.log
$TARGET-objcopy -O verilog program.elf program_incorrect.hex || true

echo "Compilation done; running hex parser..."

cd - || exit
python3 hex_parser.py
cp "$COMPILATION_DIR"/program.hex "$VERILOG_DIR"/

cd "$VERILOG_DIR" || exit
iverilog -o simv *.v
vvp simv
