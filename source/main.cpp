#include <stdio.h>
#include "my_printf.h"

int main(void) {
//d   d   d   d   d   d   d   d   i   i   i   d   d   i   i   i   i   i   d   d   i
    MyPrintf("%f %f %f %f %f %f %f %f "
             "%d %d %d "
             "%f %f "
             "%d %d %d %d %d "
             "%f %f "
             "%d\n\n",
             0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8,
             9, 10, 11,
             0.12, 0.13,
             14, 15, 16, 17, 18,
             0.19, 0.21,
             22);

    MyPrintf("%d %d %d %d %d %d %d %d "
             "%f %f %f "
             "%f %f "
             "%d %d %d %d %d "
             "%f %f "
             "%d\n\n",
             1, 2, 3, 4, 5, 6, 7, 8,
             0.9, 0.10, 0.11,
             0.12, 0.13,
             14, 15, 16, 17, 18,
             0.19, 0.21,
             22);

    MyPrintf("Floating point tests:"
             "%f %f %f %f %f %f %f %f %f %f %f %f",
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123,
             -123.123123123);
    MyPrintf("seva sosal { %f }  %s %d times %b %o (%x) %o\n", -24.00013, "huy", 10, 10, 15, 10, 15);
    printf("%f", 24.13);
    return 0;
}
