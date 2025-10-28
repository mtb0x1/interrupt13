OUT_DIR := build
SRC_DIR := src
HELLOWORLD := $(SRC_DIR)/helloworld.nasm
HELLOWORLD_OBJ := $(OUT_DIR)/helloworld.o
HELLOWORLD_BIN := $(OUT_DIR)/helloworld
UNAME_S := $(shell uname -s)
EXTRA_TARGETS := $(filter-out run, $(MAKECMDGOALS))

.PHONY: clean $(HELLOWORLD_BIN)

# Create output dir, then assemble + link
$(HELLOWORLD_BIN): $(HELLOWORLD_OBJ)
	#file $<
ifeq ($(UNAME_S),Darwin)
	clang -arch x86_64 --verbose -o $@ $< -lSystem
else ifeq ($(UNAME_S),Linux)
	ld -static -o $@ $<
endif

$(HELLOWORLD_OBJ): $(HELLOWORLD)
	mkdir -p $(OUT_DIR)
ifeq ($(UNAME_S),Darwin)
	nasm -f macho64 -g -D__$(UNAME_S) $< -o $@
else ifeq ($(UNAME_S),Linux)
	nasm -f elf64 -g -D__$(UNAME_S) $< -o $@
endif

run: $(HELLOWORLD_BIN)
ifeq ($(UNAME_S),Darwin)
	arch -x86_64 ./$(HELLOWORLD_BIN)
else
	./$(HELLOWORLD_BIN)
endif

clean:
	rm -rf $(OUT_DIR)