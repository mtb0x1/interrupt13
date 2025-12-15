OUT_DIR := build
SRC_DIR := src

# Find sources
ASM_SRCS := $(wildcard $(SRC_DIR)/*.nasm)
ASM_BINS := $(patsubst $(SRC_DIR)/%.nasm, $(OUT_DIR)/%, $(ASM_SRCS))

RUST_SRCS := $(wildcard $(SRC_DIR)/*.rs)
RUST_BINS := $(patsubst $(SRC_DIR)/%.rs, $(OUT_DIR)/%, $(RUST_SRCS))

.PHONY: all clean

all: $(ASM_BINS) $(RUST_BINS)

# Pattern rule for NASM assembly
$(OUT_DIR)/%: $(SRC_DIR)/%.nasm
	@mkdir -p $(OUT_DIR)
	nasm -f elf64 -g -D__Linux $< -o $@.o
	ld -static -o $@ $@.o
	@rm $@.o

# Pattern rule for Rust
$(OUT_DIR)/%: $(SRC_DIR)/%.rs
	@mkdir -p $(OUT_DIR)
	rustc -C panic=abort -C link-arg=-nostartfiles -O -o $@ $<

clean:
	rm -rf $(OUT_DIR)