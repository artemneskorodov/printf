#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "my_printf.h"
#include "colors.h"

static const size_t BufferSize = 2048;

static void write_result(bool same);
static void write_splitter(color_t color);

#define TEST_PRINTF(_test_num, ...) {                                               \
    memset(buffer_1, 0, BufferSize);                                                \
    memset(buffer_2, 0, BufferSize);                                                \
    if( pipe(out_pipe) != 0 ) {                                                     \
        exit(1);                                                                    \
    }                                                                               \
    dup2(out_pipe[1], STDOUT_FILENO);                                               \
    close(out_pipe[1]);                                                             \
                                                                                    \
    MyPrintf(__VA_ARGS__);                                                          \
    fflush(stdout);                                                                 \
    read(out_pipe[0], buffer_1, BufferSize);                                        \
                                                                                    \
    printf(__VA_ARGS__);                                                            \
    fflush(stdout);                                                                 \
    read(out_pipe[0], buffer_2, BufferSize);                                        \
                                                                                    \
    dup2(saved_stdout, STDOUT_FILENO);                                              \
                                                                                    \
    bool same = true;                                                               \
    if(strcmp(buffer_1, buffer_2) != 0) {                                           \
        same = false;                                                               \
    }                                                                               \
    color_printf(MAGENTA_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,                       \
        "|==============================================================|\n"        \
        "|                        Test number %.2d                        |\n"      \
        "|==============================================================|\n",       \
                 (_test_num));                                                      \
    write_splitter(YELLOW_TEXT);                                                    \
    color_printf(YELLOW_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,                        \
                 "MyPrintf output:\n");                                             \
    color_printf(DEFAULT_TEXT, NORMAL_TEXT, DEFAULT_BACKGROUND,                     \
                 "%s\n", buffer_1);                                                 \
    write_splitter(YELLOW_TEXT);                                                    \
    color_printf(YELLOW_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,                        \
                 "printf output:\n");                                               \
    color_printf(DEFAULT_TEXT, NORMAL_TEXT, DEFAULT_BACKGROUND,                     \
                 "%s\n", buffer_2);                                                 \
    write_splitter(YELLOW_TEXT);                                                    \
    write_result(same);                                                             \
    fflush(stdout);                                                                 \
}

void write_splitter(color_t color) {
    color_printf(color, BOLD_TEXT, DEFAULT_BACKGROUND,
        "----------------------------------------------------------------\n");
}

void write_result(bool same) {
    if(same) {
        color_printf(GREEN_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,
            "|==============================================================|\n"
            "|                              OK                              |\n"
            "|==============================================================|\n\n\n\n\n");
    }
    else {
        color_printf(RED_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,
            "|==============================================================|\n"
            "|                             ERROR                            |\n"
            "|==============================================================|\n\n\n\n\n");
    }
}

int main(void) {
    char buffer_1[BufferSize] = {0};
    char buffer_2[BufferSize] = {0};
    int out_pipe[2];
    int saved_stdout;

    saved_stdout = dup(STDOUT_FILENO);

    TEST_PRINTF(1,
                "%f %f %f",
                123.4, 123.4, 123.4);
    TEST_PRINTF(2,
                "%d   %f   %f   %d   %d   %f   %d   %f   %d   %d   %d   %f   %f   %d   %f   %d   %f   %d   %f   %f   %f   %f   %d",
                  1,  .2,  .3,   4,   5,  .6,   7,  .8,   9,  10,  11, .12, .13,  14, .15,  16, .17,  18, .19, .20, .21, .22,  23);
    TEST_PRINTF(3,
                "%s %d %f",
                "Testing string with no much symbols",
                12,
                12.3);
    TEST_PRINTF(4,
                "%s",
                "Very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "Very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "Very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "very very very very very very very very very very very very very very very very very very very "
                "long string");
    return EXIT_SUCCESS;
}
