OUT_DIR := build
SRC_DIR := src
MAIN := $(SRC_DIR)/main.nasm
MAIN_OBJ := $(OUT_DIR)/main.o
MAIN_BIN := $(OUT_DIR)/main
UNAME_S := $(shell uname -s)

.PHONY: all clean run

all: $(MAIN_BIN)

# Create output dir, then assemble + link
$(MAIN_BIN): $(MAIN_OBJ)
	file $<
ifeq ($(UNAME_S),Darwin)
	clang -arch x86_64 --verbose -o $@ $< -lSystem
else ifeq ($(UNAME_S),Linux)
	ld -static -o $@ $<
else
	# Windows link. Use gcc as a linker driver.
	# -nostdlib is needed because we provide our own _start entry point.
	gcc -o $@ $< -lkernel32 -nostdlib
endif

$(MAIN_OBJ): $(MAIN)
	mkdir -p $(OUT_DIR)
ifeq ($(UNAME_S),Darwin)
	nasm -f macho64 -g -D__$(UNAME_S) $< -o $@
else ifeq ($(UNAME_S),Linux)
	nasm -f elf64 -g -D__$(UNAME_S) $< -o $@
else
	nasm -f win64 -g -D__$(UNAME_S) $< -o $@
endif

run: all
ifeq ($(UNAME_S),Darwin)
	arch -x86_64 ./$(MAIN_BIN)
else
	./$(MAIN_BIN)
endif

clean:
	rm -rf $(OUT_DIR)