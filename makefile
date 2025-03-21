FLAGS:=-I ./include 					\
	   -I ./printf						\
	   -no-pie							\
	   -Wshadow							\
	   -Winit-self						\
	   -Wredundant-decls				\
	   -Wcast-align						\
	   -Wundef							\
	   -Wfloat-equal					\
	   -Winline 						\
	   -Wunreachable-code 				\
	   -Wmissing-declarations 			\
	   -Wmissing-include-dirs 			\
	   -Wswitch-enum 					\
	   -Wswitch-default 				\
	   -Weffc++ 						\
	   -Wmain 							\
	   -Wextra 							\
	   -Wall 							\
	   -g -pipe -fexceptions 			\
	   -Wcast-qual 						\
	   -Wconversion 					\
	   -Wctor-dtor-privacy 				\
	   -Wempty-body 					\
	   -Wformat-security 				\
	   -Wformat=2 						\
	   -Wignored-qualifiers 			\
	   -Wlong-long						\
	   -Wno-missing-field-initializers 	\
	   -Wnon-virtual-dtor 				\
	   -Woverloaded-virtual 			\
	   -Wpointer-arith 					\
	   -Wsign-promo 					\
	   -Wstack-protector 				\
	   -Wstrict-aliasing				\
	   -Wtype-limits					\
	   -Wwrite-strings 					\
	   -Werror=vla 						\
	   -D_DEBUG 						\
	   -D_EJUDGE_CLIENT_SIDE
BINDIR:=bin
OUTPUT:=printf_test.out
SRCDIR:=source
SOURCE:=$(wildcard ${SRCDIR}/*.cpp)
OBJECTS:=$(addsuffix .o,$(addprefix ${BINDIR}/,$(basename $(notdir ${SOURCE}))))
ASM_FILE:=printf/my_printf.s
ASM_OBJ:=my_printf.o
ASM_LST:=my_printf.lst

all: ${OUTPUT}

${OUTPUT}:${OBJECTS}
	g++ ${FLAGS} ${OBJECTS} ${BINDIR}/${ASM_OBJ} -o ${OUTPUT}
${OBJECTS}: ${SOURCE} ${BINDIR} ${ASM_OBJ}
	$(foreach SRC,${SOURCE},$(shell g++ -c ${SRC} ${FLAGS} -o $(addsuffix .o,$(addprefix ${BINDIR}/,$(basename $(notdir ${SRC}))))))
${ASM_OBJ}:
	nasm -f elf64 -l ${BINDIR}/${ASM_LST} ${ASM_FILE} -o ${BINDIR}/${ASM_OBJ}
clean:
	rm -rf ${BINDIR}
${SOURCE}:

${BINDIR}:
	mkdir ${BINDIR}
