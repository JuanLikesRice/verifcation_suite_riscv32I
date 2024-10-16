// Define memory-mapped address for the LED
#define LED_BASE 0x20000000  // Hypothetical base address for memory-mapped LED

// Function to write to the memory-mapped LED register
void write_led(int state) {
    *((volatile int*)LED_BASE) = state;
}

int main() {
    // Initialize two variables
    int value1 = 5;
    int value2 = 10;
    int result;

    // Perform the addition
    result = value1 + value2;

    // If the result is 15, turn the LED on, else turn it off
    if (result == 15) {
        write_led(1);  // Turn LED on
    } else {
        write_led(0);  // Turn LED off
    }

    // Infinite loop to keep the processor running
    while (1) {
        // No further action, just looping indefinitely
    }

    return 0;
}
