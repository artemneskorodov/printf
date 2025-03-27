#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "my_printf.h"
#include "colors.h"

static const size_t BufferSize = 2048;

static void write_output(const char *buffer_1, const char *buffer_2);

#define TEST_PRINTF(_test_num, _description, ...) {                                 \
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
    color_t frame_color = GREEN_TEXT;                                               \
    const char *result = "  OK  ";                                                  \
    if(strcmp(buffer_1, buffer_2) != 0) {                                           \
        result = "ERROR!";                                                          \
        frame_color = RED_TEXT;                                                     \
    }                                                                               \
                                                                                    \
    color_printf(frame_color, BOLD_TEXT, DEFAULT_BACKGROUND,                        \
        "\n\n\n"                                                                    \
        "╔══════════════════════════════╦══════════════════════════════╗\n"         \
        "║           Test %.2d            ║            %s            ║\n"           \
        "╠══════════════════════════════╩══════════════════════════════╣\n"         \
        "║ %59s ║\n"                                                                \
        "╚═════════════════════════════════════════════════════════════╝\n",        \
                 (_test_num), result, (_description));                              \
    if(show_result) {                                                               \
        write_output(buffer_1, buffer_2);                                           \
    }                                                                               \
    fflush(stdout);                                                                 \
}

void write_output(const char *buffer_1, const char *buffer_2) {
    color_printf(MAGENTA_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,
        "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━OUTPUTS━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n");
    color_printf(YELLOW_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,
        "╭─────────────────────────────────────────────────────────────╮\n"
        "╰─ MyPrintf output: ──────────────────────────────────────────╯\n");
    color_printf(DEFAULT_TEXT, NORMAL_TEXT, DEFAULT_BACKGROUND,
        "%s\n", buffer_1);
    color_printf(YELLOW_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,
        "╭─────────────────────────────────────────────────────────────╮\n"
        "╰─ printf output: ────────────────────────────────────────────╯\n");
    color_printf(DEFAULT_TEXT, NORMAL_TEXT, DEFAULT_BACKGROUND,
        "%s\n", buffer_2);
    color_printf(MAGENTA_TEXT, BOLD_TEXT, DEFAULT_BACKGROUND,
        "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━OUTPUTS━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
}

int main(int argc, const char *argv[]) {
    bool show_result = false;
    if(argc == 2 && strcmp(argv[1], "-p") == 0) {
        show_result = true;
    }
    char buffer_1[BufferSize] = {0};
    char buffer_2[BufferSize] = {0};
    int out_pipe[2];
    int saved_stdout;

    saved_stdout = dup(STDOUT_FILENO);

    TEST_PRINTF(1,  "Check tests",
                "%f %f %f",
                123.4, 123.4, 123.4);
    TEST_PRINTF(2,  "Check doubles and default arguments",
                "%d %f %f %d %d %f %d %f %d \n"
                "%d %d %f %f %d %f %d %f\n"
                "%d %f %f %f %f %d",
                1, .2, .3, 4, 5, .6, 7, .8, 9, 10, 11,
                .12, .13, 14, .15, 16, .17, 18, .19, .20, .21, .22, 23);
    TEST_PRINTF(3,  "Check short string",
                "%s %d %f",
                "Testing string with no much symbols",
                12,
                12.3);
    TEST_PRINTF(4,  "Check long string",
                "%s",
                "Very very very very very very very very very very very very\n"
                "very very very very very very very very very very very very\n"
                "very very very very very very very very very very very very\n"
                "very very very very very very very very very very very very\n"
                "very very very very very very very very very very very very\n"
                "very very very very very very very very very very very very\n"
                "long string");

    int a = 0;
    printf("%p \n", &a);

    MyPrintf("%b %o %x %s %s %s %s %s %f aovaovavoaov", 12 ,12 , 13, "aviva",  "aviva", "aviva", "aviva", "aviva", 123.43764);
    return EXIT_SUCCESS;
}
