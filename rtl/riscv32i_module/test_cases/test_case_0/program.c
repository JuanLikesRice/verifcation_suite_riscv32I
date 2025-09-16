#include "constants.h"

int main() {
    int array[10];  
    int sum = 0;
    for (int i = 0; i < 10; i++) {
        array[i] = i + 1;}
    for (int i = 0; i < 10; i++) {
                sum += array[i];
    write_to_peripheral(PERIPHERAL_S2, sum);}
    write_to_peripheral(PERIPHERAL_S1, sum);

    if (sum == 55) {
                write_to_peripheral(PERIPHERAL_S3,0xDEADF00F);
    } else {    write_to_peripheral(PERIPHERAL_BASE, 0x0BADF00D);}
    
    int sum_while;
    sum_while = 0;
    while (1) {   

        sum_while += 1;
        if (sum_while == 10) {
            break;
        }
     }
     write_to_peripheral(PERIPHERAL_BASE, 0xDEADBEEF);
     while (1) {

     }
    return 0; 
}



