# III Grammar — cross-platform GNU Make.
# Targets: all (default), lib, tool, test, clean.

ROOT      := $(abspath $(CURDIR)/..)
III_DIR   := $(abspath $(ROOT)/..)
LEX_DIR   := $(III_DIR)/LEXICON
GRAM_DIR  := $(ROOT)
BUILD_DIR := $(GRAM_DIR)/build
OBJ_DIR   := $(BUILD_DIR)/obj

CC      ?= gcc
AR      ?= ar
CFLAGS  ?= -std=c11 -Wall -Wextra -Werror -O2 \
           -I$(GRAM_DIR)/include -I$(LEX_DIR)/include
# Workaround for Agent-C duplicate iiip_parse_qualified_name symbol.
LDFLAGS ?= -Wl,--allow-multiple-definition

ifeq ($(OS),Windows_NT)
    EXE := .exe
else
    EXE :=
endif

LIB     := $(BUILD_DIR)/libiii_grammar.a
LEX_LIB := $(LEX_DIR)/build/libiii_lex.a
TOOL    := $(BUILD_DIR)/iii_parse_tool$(EXE)
TESTBIN := $(BUILD_DIR)/iii_grammar_test$(EXE)

SRCS      := $(wildcard $(GRAM_DIR)/src/*.c)
OBJS      := $(patsubst $(GRAM_DIR)/src/%.c,$(OBJ_DIR)/%.o,$(SRCS))
TEST_SRCS := $(wildcard $(GRAM_DIR)/tests/*.c)
TEST_OBJS := $(patsubst $(GRAM_DIR)/tests/%.c,$(OBJ_DIR)/tests/%.o,$(TEST_SRCS))

.PHONY: all lib tool test clean run-test

all: lib tool test

lib: $(LIB)

tool: $(TOOL)

test: $(TESTBIN)
	@echo "==> Running test suite"
	$(TESTBIN)

run-test: test

$(LIB): $(OBJS) | $(BUILD_DIR)
	@rm -f $@
	$(AR) rcs $@ $(OBJS)

$(OBJ_DIR)/%.o: $(GRAM_DIR)/src/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/tests/%.o: $(GRAM_DIR)/tests/%.c | $(OBJ_DIR)/tests
	$(CC) $(CFLAGS) -c $< -o $@

$(TOOL): $(GRAM_DIR)/tools/iii_parse_tool.c $(LIB) $(LEX_LIB) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(LIB) $(LEX_LIB) $(LDFLAGS)

$(TESTBIN): $(TEST_OBJS) $(LIB) $(LEX_LIB) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $(TEST_OBJS) $(LIB) $(LEX_LIB) $(LDFLAGS)

$(BUILD_DIR) $(OBJ_DIR) $(OBJ_DIR)/tests:
	@mkdir -p $@

clean:
	@rm -rf $(OBJ_DIR) $(LIB) $(TOOL) $(TESTBIN)
	@echo "==> Cleaned."
