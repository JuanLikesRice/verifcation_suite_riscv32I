#include "constants.h"

int main() {
    int array[30];  
    int sum = 0;
    for (int i = 0; i < 30; i++) {
        array[i] = i + 1;}
    for (int i = 0; i < 30; i++) {
                sum += array[i];
    write_to_peripheral(PERIPHERAL_S2, sum);
                    }
    write_to_peripheral(PERIPHERAL_S1, sum);

    if (sum == 465) {
                write_to_peripheral(PERIPHERAL_BASE, 0xDEADBEEF);
    } else {    write_to_peripheral(PERIPHERAL_BASE, 0x0BADF00D);}
    while (1) {    }
    return 0; 
}




