#!/bin/bash

# Define directories
INPUT_DIR="inputs"
COMPILATION_DIR="compilation"
VERILOG_DIR="verilog"
# Delete all files in "compilation" directory
rm -rf "$COMPILATION_DIR"/*
# Copy all files from "inputs" to "compilation"
cp "$INPUT_DIR"/* "$COMPILATION_DIR"/
# Change directory to "compilation"
cd "$COMPILATION_DIR" || exit
# Run commands here
# (Replace the following line with actual commands to be executed)
echo "Running compilation commands..."
riscv32-unknown-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -nostdlib -ffreestanding -o program.o -c program.c
riscv32-unknown-elf-as  -march=rv32i_zicsr -o startup.o startup.S
riscv32-unknown-elf-gcc  -T link.ld -e _start -nostdlib -o program.elf program.o startup.o /opt/riscv/lib/gcc/riscv32-unknown-elf/14.2.0/libgcc.a
riscv32-unknown-elf-objcopy -O binary program.elf program.bin
riscv32-unknown-elf-readelf -h program.elf
riscv32-unknown-elf-objdump -D -b binary -m riscv:rv32 program.bin > program_disassembly.txt
riscv32-unknown-elf-objdump -D program.elf &> instrictions.log
riscv32-unknown-elf-objcopy -O verilog program.elf program_incorrect.hex

timeout -s INT -k 1s 3s stdbuf -oL -eL spike -l --isa=RV32I_zicsr -m0x2000:0x2010 program.elf &> spike.log

echo "Complilation run, python next step"
cd - || exits
python3 hex_parser.py
cp "$COMPILATION_DIR"/program.hex "$VERILOG_DIR"/
cd "$VERILOG_DIR" || exit
iverilog -o simv *.v
vvp simv