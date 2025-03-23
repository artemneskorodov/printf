# MyPrintf
## About the project
This is custom implementation of limited printf. Supported formats are:
- `%c` for character
- `%b` for binary number
- `%x` for hexadecimal number
- `%o` for octal number
- `%%` for %
- `%d` for decimal number
- `%s` for string
- `%f` for double number
Function supports fastcall and can be used from C and C++.
## Install
* Cloning a repository
```bash
    git clone https://github.com/artemneskorodov/printf.git
```
* Running tests
```bash
    cd printf
```
```bash
    make
```
```bash
    bin/printf
```
You can also use flag '-p' to make test program show cases.
* Including to your project
```cpp
    #include "my_printf.h"
    int main(void) {
        MyPrintf("Testing output of double number: %f", 123.456);
    }
```
```bash
    g++ 'your file' -I {path to printf}/include {path to printf}/bin/my_printf.o
```
You can also copy header 'include/my_printf.h' and object 'bin/my_printf.o' to your working folder
## Peculiarities
### Extensibility
Jump table is used to handle different specifiers in this project, so it is easy to add new formats until they get to large. If it will be needed to implement formats with additional parameters (for expample '%.2d' to write integer with 2 symbols), there is a simple way to parse formats because this parameters have same structure and can be skipped, and the handler of specific format will get that parameters.
### Optimization
To avoid a lot of system calls, which are too slow, this implementation of printf writes everything to buffer. It calls clearing when there is no place to write something. One problem is that function calls clearing buffer before return and does not provide different calls clearing, but it can be easily implemented.
### Tests
To test this project, there is a file 'printf_test.cpp'. You can check the tests in example. It is neccessary to avoid changing variables and constants names as they are used in huge macro that is a bit cringe. But as it is only test for progject, i did not work through it well.
Test redirects stdout to pipe. Than it calls libc printf and reads it to first buffer. Than it does the same with MyPrintf. It uses strcmp to check that buffers are the same.
Test that are provided in examples checks doubles output and long string output. The main test is that with a lot of integers and doubles. It checks that arguments from different registers set and from stack are parsed in a right order.
