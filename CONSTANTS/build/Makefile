# III CONSTANTS — gcc build (Windows MinGW / MSYS / *nix)
CC      ?= gcc
CSTD    := -std=c11
WARN    := -Wall -Wextra -Werror
OPT     := -O2
INCS    := -I../include -I../../LEXICON/include
CFLAGS  := $(CSTD) $(WARN) $(OPT) $(INCS)

LEX_LIB := ../../LEXICON/build/libiii_lex.a
SRC     := $(wildcard ../src/*.c)
OBJ     := $(patsubst ../src/%.c,obj/%.o,$(SRC))

LIB     := libiii_constants.a
TOOL    := iii_constants_tool.exe
TEST    := iii_constants_test.exe

.PHONY: all clean test
all: $(LIB) $(TOOL) $(TEST)

obj/%.o: ../src/%.c
	@mkdir -p obj
	$(CC) $(CFLAGS) -c $< -o $@

$(LIB): $(OBJ)
	ar rcs $@ $^

$(TOOL): ../tools/iii_constants_tool.c $(LIB) $(LEX_LIB)
	$(CC) $(CFLAGS) $< $(LIB) $(LEX_LIB) -o $@

$(TEST): $(wildcard ../tests/*.c) $(LIB) $(LEX_LIB)
	$(CC) $(CFLAGS) ../tests/*.c $(LIB) $(LEX_LIB) -o $@

test: $(TEST)
	./$(TEST)

clean:
	rm -rf obj $(LIB) $(TOOL) $(TEST)
