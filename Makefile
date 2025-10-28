OUT_DIR := build
SRC_DIR := src
HELLOWORLD := $(SRC_DIR)/helloworld.nasm
HELLOWORLD_OBJ := $(OUT_DIR)/helloworld.o
HELLOWORLD_BIN := $(OUT_DIR)/helloworld
HELLO := $(SRC_DIR)/hello.nasm
HELLO_OBJ := $(OUT_DIR)/hello.o
HELLO_BIN := $(OUT_DIR)/hello
UNAME_S := $(shell uname -s)
EXTRA_TARGETS := $(filter-out run hello, $(MAKECMDGOALS))
TARGET := $(if $(filter helloworld, $(EXTRA_TARGETS)), helloworld, $(if $(filter hello, $(EXTRA_TARGETS)), hello, helloworld))
TARGET_BIN := $(OUT_DIR)/$(TARGET)

.PHONY: clean $(HELLOWORLD_BIN) $(HELLO_BIN) all run hello

all: $(HELLOWORLD_BIN) $(HELLO_BIN)

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

$(HELLO_BIN): $(HELLO_OBJ)
	#file $<
ifeq ($(UNAME_S),Darwin)
	clang -arch x86_64 --verbose -o $@ $< -lSystem
else ifeq ($(UNAME_S),Linux)
	ld -static -o $@ $<
endif

$(HELLO_OBJ): $(HELLO)
	mkdir -p $(OUT_DIR)
ifeq ($(UNAME_S),Darwin)
	nasm -f macho64 -g -D__$(UNAME_S) $< -o $@
else ifeq ($(UNAME_S),Linux)
	nasm -f elf64 -g -D__$(UNAME_S) $< -o $@
endif

clean:
	rm -rf $(OUT_DIR)