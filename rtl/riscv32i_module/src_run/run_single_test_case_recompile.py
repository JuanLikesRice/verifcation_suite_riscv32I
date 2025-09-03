import os
import re
import shutil
import subprocess
import sys

def copy_file(src, dst):
    """Copy a file from src to dst, overwriting if it exists."""
    shutil.copy2(src, dst)
    print(f"Copied {src} to {dst}")

def copy_directory(src, dst):
    """Copy contents from src directory to dst directory."""
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    print(f"Copied contents from {src} to {dst}")

def run_command(command, cwd):
    """Run a shell command in the specified directory."""
    result = subprocess.run(command, cwd=cwd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command '{command}' failed with error:\n{result.stderr}")
        sys.exit(1)
    else:
        print(f"Command '{command}' executed successfully:\n{result.stdout}")

def read_test_case_number(file_path):
    """Read the test case number from the specified file."""
    try:
        with open(file_path, 'r') as file:
            test_case_number = file.read().strip()
            return test_case_number
    except FileNotFoundError:
        print(f"Error: The file {file_path} does not exist.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        sys.exit(1)

def write_test_case_number(file_path, test_case_number):
    """Write the test case number to the specified file."""
    try:
        with open(file_path, 'w') as file:
            file.write(test_case_number)
            print(f"Wrote test case number {test_case_number} to {file_path}")
    except Exception as e:
        print(f"Error writing to {file_path}: {e}")
        sys.exit(1)

def parse_compilation_log(log_path):
    """
    Parse the compilation.log file to extract the entry point address.
    Expected line: "Entry point address:               0x1cc" (or any 32-bit hex number)
    Returns the hex value as an 8-digit string (e.g., "000001CC").
    """
    if not os.path.exists(log_path):
        print(f"Error: {log_path} does not exist.")
        sys.exit(1)
    
    with open(log_path, 'r') as file:
        for line in file:
            if "Entry point address:" in line:
                match = re.search(r'Entry point address:\s*(0x[0-9a-fA-F]+)', line)
                if match:
                    hex_val = match.group(1)  # e.g., "0x1cc"
                    try:
                        value_int = int(hex_val, 16)
                    except ValueError:
                        print("Error: Could not convert entry point to an integer.")
                        sys.exit(1)
                    formatted_hex = format(value_int, '08X')
                    return formatted_hex
    print("Error: Entry point address not found in compilation.log.")
    sys.exit(1)

def modify_riscv_tb(v_file_path, new_entry_hex):
    """
    Parse riscv32iTB.v and update the line containing "parameter initial_pc"
    to be: 
        parameter initial_pc    = 32'h<new_entry_hex>
    """
    if not os.path.exists(v_file_path):
        print(f"Error: {v_file_path} does not exist.")
        sys.exit(1)

    temp_file = v_file_path + ".tmp"
    replaced = False

    with open(v_file_path, 'r') as infile, open(temp_file, 'w') as outfile:
        for line in infile:
            if "parameter initial_pc" in line:
                new_line = f"    parameter initial_pc    = 32'h{new_entry_hex}\n"
                outfile.write(new_line)
                replaced = True
                print(f"Updated initial_pc to 32'h{new_entry_hex}")
            else:
                outfile.write(line)

    if not replaced:
        print("Warning: No line with 'parameter initial_pc' was found in riscv32iTB.v.")
    shutil.move(temp_file, v_file_path)

# def check_sim_log(sim_log_path, test_case_number):
#     """
#     Parse sim.log to check if it contains the success string.
#     If found, print a success message including the test case number.
#     """
#     if not os.path.exists(sim_log_path):
#         print(f"Error: {sim_log_path} does not exist.")
#         sys.exit(1)
    
#     with open(sim_log_path, 'r') as file:
#         content = file.read()
#         if "----TB FINISH:Test Passed----" in content:
#             print(f"\n\n\n\n-----TEST PASSED: success code for test case {test_case_number} found -----\n\n")
#         else:
#             print(f"\n\n\n\n-----TEST PASSED: success code for test case {test_case_number} found -----Test case {test_case_number} did not pass as expected.\n\n\n\n")

def check_sim_log(sim_log_path, test_case_number):
    """
    Parse sim.log to check for the success string and extract the last cycle count.
    Expected cycle count line format: "Cycle_count   {number},"
    Prints a message including test case number, pass/fail status, and last cycle count.
    """
    if not os.path.exists(sim_log_path):
        print(f"Error: {sim_log_path} does not exist.")
        sys.exit(1)
    
    passed = False
    cycle_count = "N/A"
    
    with open(sim_log_path, 'r') as file:
        for line in file:
            if "----TB FINISH:Test Passed----" in line:
                passed = True
            # Look for a cycle count line, e.g., "Cycle_count   12345,"
            match = re.search(r"Cycle_count\s+(\d+),", line)
            if match:
                cycle_count = match.group(1)
    
    if passed:
        print(f"\n\n-----TEST PASSED: success code for test case {test_case_number} found. Cycle count: {cycle_count}-----\n")
    else:
        print(f"\n\n-----TEST FAILED: success code for test case {test_case_number} NOT found: {cycle_count}          -----\n\n\n\n")

        # print(f"Test case {test_case_number} did not pass as expected. Cycle count: {cycle_count}")



import os
import shutil
import subprocess

def change_dir_and_run(
    target_dir,
    shell_script,
    files_to_swap=None,   # list of tuples: [(source_file, target_file), ...]
    backup_suffix=".bak"
):
    original_dir = os.getcwd()
    try:
        print(f"Changing directory to: {target_dir}")
        os.chdir(target_dir)

        # Backup and swap files
        # if files_to_swap:
        #     for src, dest in files_to_swap:
        #         if os.path.exists(dest):
        #             backup_name = dest + backup_suffix
        #             print(f"Backing up {dest} to {backup_name}")
        #             shutil.move(dest, backup_name)
        #         print(f"Copying {src} to {dest}")
        #         shutil.copy(src, dest)

        # Run the shell script
        print(f"Running script: {shell_script}")
        subprocess.run(["bash", shell_script], check=True)

    except Exception as e:
        print(f"Error occurred: {e}")
    finally:
        os.chdir(original_dir)
        print(f"Returned to original directory: {original_dir}")

# Example usage

import os
import re

def shift_hex_file(src_path, dst_path, offset=0x2000, allow_negative=False, only_if_ge=False):
    addr_pat = re.compile(r'^(\s*)@([0-9a-fA-F]+)(\s*)(?:[#;].*)?$')

    with open(src_path, "r") as fin, open(dst_path, "w") as fout:
        for raw in fin:
            line = raw.rstrip("\n")
            m = addr_pat.match(line)
            if not m:
                fout.write(raw)
                continue

            lead, hexstr, trail = m.group(1), m.group(2), m.group(3)
            width = len(hexstr)
            addr = int(hexstr, 16)

            if only_if_ge and addr < offset:
                fout.write(raw)
                continue

            new_addr = addr - offset
            if new_addr < 0 and not allow_negative:
                raise ValueError(
                    f"Address {addr:#x} becomes negative after subtracting {offset:#x}"
                )

            hex_new = f"{new_addr & ((1 << (4*width)) - 1):0{width}X}"
            fout.write(f"{lead}@{hex_new}{trail}\n")

# Example usage in your flow:



def main():
    rtl_directory = os.getcwd()
    assembly_code_dir = os.path.join(rtl_directory, "assembly_code")
    test_case_number_file = os.path.join(assembly_code_dir, "test_case_number.txt")
    print(f"Current directory: {rtl_directory}")

    # Determine test case number: from command-line argument or from file.
    if len(sys.argv) > 1:
        test_case_number = sys.argv[1]
    else:
        if os.path.exists(test_case_number_file):
            test_case_number = read_test_case_number(test_case_number_file)
        else:
            print("Error: No test case number provided and test_case_number.txt not found.")
            sys.exit(1)

    test_case_dir = os.path.join(rtl_directory, f"test_cases/test_case_{test_case_number}")
    if not os.path.exists(test_case_dir):
        print(f"Error: Test case directory {test_case_dir} does not exist.")
        sys.exit(1)





    copy_directory(test_case_dir, assembly_code_dir)
    write_test_case_number(test_case_number_file, test_case_number)

    change_dir_and_run( 
    target_dir="../../", 
    shell_script="update_directory_automatically.sh")
    copy_directory(assembly_code_dir, test_case_dir)


    # Copy program.hex from the test case directory to the RTL directory.
    src_program_hex = os.path.join(test_case_dir, "program.hex")
    dst_program_hex = os.path.join(rtl_directory, "program.hex")
    # src_program_hex = os.path.join(test_case_dir, "program.hex")
    dst_program_hex_l = os.path.join(rtl_directory, "out.hex")
    shift_hex_file(src_program_hex, dst_program_hex_l, offset=0x2000)
    copy_file(src_program_hex, dst_program_hex)

    # Parse compilation.log for entry point address.
    compilation_log_path = os.path.join(test_case_dir, "compilation.log")
    entry_point_hex = parse_compilation_log(compilation_log_path)
    print(f"Parsed entry point: 32'h{entry_point_hex}")

    # Modify riscv32iTB.v with the new entry point address.
    riscv_tb_path = os.path.join(rtl_directory, "riscv32iTB.v")
    modify_riscv_tb(riscv_tb_path, entry_point_hex)

    # Run the "./run" command in the RTL directory.
    run_command("./run", rtl_directory)

    # Parse sim.log for the success message.
    sim_log_path = os.path.join(rtl_directory, "sim.log")

    # Copy output files to the outputs directory in the test case.
    output_files = ["sim.log", "sim.vcd"]  # Add other output files as needed.
    for output_file in output_files:
        src_output_file = os.path.join(rtl_directory, output_file)
        if os.path.exists(src_output_file):
            dst_output_dir = os.path.join(test_case_dir, "outputs")
            os.makedirs(dst_output_dir, exist_ok=True)
            copy_file(src_output_file, os.path.join(dst_output_dir, output_file))
        else:
            print(f"Warning: {src_output_file} does not exist.")
    
    check_sim_log(sim_log_path, test_case_number)

if __name__ == "__main__":
    main()
