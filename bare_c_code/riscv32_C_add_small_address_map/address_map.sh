python3 gen_linker.py      \
  --start           0x2000 \
  --instr-words       2048 \
  --rom-words          512 \
  --peri-words         512 \
  --data-words        4096 \
  --stack-words       2048 \
  --out-ld  inputs/link.ld        \
  --out-h   inputs/include/constants.h \
  --out-v   memory_map.vh
