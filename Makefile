OUT_DIR := build
SRC_DIR := src
MAIN := $(SRC_DIR)/main.nasm
MAIN_OBJ := $(OUT_DIR)/main.o
MAIN_BIN := $(OUT_DIR)/main

.PHONY: all clean run

all: $(MAIN_BIN)

# Create output dir, then assemble + link
$(MAIN_BIN): $(MAIN_OBJ)
	ld -static -o $@ $<

$(MAIN_OBJ): $(MAIN)
	mkdir -p $(OUT_DIR)
	nasm -f elf64 -g $< -o $@

run: all
	./$(MAIN_BIN)

clean:
	rm -rf $(OUT_DIR)
