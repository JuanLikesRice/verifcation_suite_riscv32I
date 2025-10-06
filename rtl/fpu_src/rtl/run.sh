iverilog -g2001 -o sim fpu_adder.v 
vvp sim
# python3 src_run/fp32.py 1.25 751.375