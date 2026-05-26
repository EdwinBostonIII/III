CC      ?= cc
CFLAGS  ?= -std=c11 -Wall -Wextra -Wno-unused-parameter -O2 -Iinclude
SRC     := $(wildcard src/*.c)
OBJ     := $(patsubst src/%.c,build/obj/%.o,$(SRC))
LIB     := build/libiii_lex.a
TOOL    := build/iii_lex_tool
TEST    := build/iii_lex_test

.PHONY: all clean test
all: $(LIB) $(TOOL) $(TEST)

build/obj/%.o: src/%.c
	@mkdir -p build/obj
	$(CC) $(CFLAGS) -c $< -o $@

$(LIB): $(OBJ)
	ar rcs $@ $^

$(TOOL): tools/iii_lex_tool.c $(LIB)
	$(CC) $(CFLAGS) $< $(LIB) -o $@

$(TEST): $(wildcard tests/*.c) $(LIB)
	$(CC) $(CFLAGS) tests/*.c $(LIB) -o $@

test: $(TEST)
	./$(TEST)

clean:
	rm -rf build/obj $(LIB) $(TOOL) $(TEST)
