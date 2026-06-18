CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -O2
BUILD_DIR := build
BIN := $(BUILD_DIR)/c-service

.PHONY: all clean test

all: $(BIN)

$(BIN): main.c
	@mkdir -p $(BUILD_DIR)
	@$(CC) $(CFLAGS) -o $(BIN) main.c

test: $(BIN)
	@$(BIN) --healthz | grep -F '"status":"ok"' >/dev/null
	@$(BIN) --hello | grep -F 'hello from c-service' >/dev/null
	@$(BIN) --info | grep -F '"runtime":"native-c"' >/dev/null
	@$(BIN) --info | grep -F '"port":8050' >/dev/null

clean:
	rm -rf $(BUILD_DIR)
