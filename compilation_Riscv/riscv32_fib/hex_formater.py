def parse_bin_file(input_bin, output_filename, start_address=0x00000100):
    parsed_output = []
    address = start_address
    data_list = []
    
    with open(input_bin, 'rb') as bin_file:
        while True:
            # Read 4 bytes (32-bit word)
            word = bin_file.read(4)
            if len(word) < 4:
                break  # Exit if we reach the end of the file
            
            # Convert word to hex in little-endian format
            hex_word = ''.join([f'{b:02X}' for b in word[::-1]])
            data_list.append(hex_word)
    
    # Write parsed output with appropriate @ markers
    with open(output_filename, 'w') as outfile:
        outfile.write(f"@{address:08X}\n")
        
        # Group words into blocks and handle any necessary address markers
        for i in range(0, len(data_list), 4):
            if i > 0 and i % 4 == 0:
                # Assume here that you handle address gaps separately if needed
                address += 16
                outfile.write(f"@{address:08X}\n")
            # Write the data list in the appropriate format
            outfile.write('\n'.join(data_list[i:i+4]) + '\n')

# Example usage
parse_bin_file('program.bin', 'parsed.hex')
