# III TYPES — POSIX makefile.
CFLAGS  = -std=c11 -Wall -Wextra -Werror -O2 -Iinclude -I../LEXICON/include -I../GRAMMAR/include
LDFLAGS = -Wl,--allow-multiple-definition
SRCS = src/errors.c src/hexad.c src/cic.c src/type_repr.c src/bidir.c
OBJS = $(SRCS:src/%.c=build/obj/%.o)
LIB  = build/libiii_types.a
LEX  = ../LEXICON/build/libiii_lex.a
GRM  = ../GRAMMAR/build/libiii_grammar.a

all: $(LIB) build/iii_types_tool build/iii_types_test

build/obj/%.o: src/%.c
	mkdir -p build/obj
	gcc $(CFLAGS) -c $< -o $@

$(LIB): $(OBJS)
	ar rcs $@ $(OBJS)

build/iii_types_tool: tools/iii_types_tool.c $(LIB)
	gcc $(CFLAGS) $< $(LIB) $(LEX) $(LDFLAGS) -o $@

build/iii_types_test: tests/test_main.c $(LIB)
	gcc $(CFLAGS) $< $(LIB) $(GRM) $(LEX) $(LDFLAGS) -o $@

test: build/iii_types_test
	./build/iii_types_test

clean:
	rm -rf build
