extern "C" void MyPrintf(const char *format, ...);

int main(void) {
    MyPrintf("seva sosal %s %d times %b %x\n", "huy", 10, 10, 10);
    return 0;
}
