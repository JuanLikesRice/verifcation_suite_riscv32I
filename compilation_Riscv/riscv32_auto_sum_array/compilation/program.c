#define PERIPHERAL_BASE 0x1A000000  // Base address for memory-mapped I/O (MMIO)

// Function to write to memory-mapped I/O
void write_to_peripheral(int value) {
    volatile int* periph_addr = (int*)(PERIPHERAL_BASE);
    *periph_addr = value;  // Write the sum to the peripheral address
}

int main() {
    // Define an array of integers
    int array[] = {10, 20, 30, 40, 50};  // Example array of values
    int sum = 0;
    int N = sizeof(array) / sizeof(array[0]);  // Number of elements in the array

    // Sum the elements of the array
    for (int i = 0; i < N; i++) {
        sum += array[i];
    }

    // Write the sum to memory-mapped I/O (e.g., a simulated peripheral)
    write_to_peripheral(sum);

    return 0;  // End of program
}
