CXX ?= c++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2
BUILD_DIR := build
BIN := $(BUILD_DIR)/cpp-service

.PHONY: all clean test

all: $(BIN)

$(BIN): main.cpp
	@mkdir -p $(BUILD_DIR)
	@$(CXX) $(CXXFLAGS) -o $(BIN) main.cpp

test: $(BIN)
	@$(BIN) --healthz | grep -F '"status":"ok"' >/dev/null
	@$(BIN) --hello | grep -F 'hello from cpp-service' >/dev/null
	@$(BIN) --info | grep -F '"runtime":"native-cpp"' >/dev/null
	@$(BIN) | grep -F '"runtime":"native-cpp"' >/dev/null
	@output="$$( $(BIN) --missing 2>&1)"; status="$$?"; test "$$status" -eq 1; test "$$output" = '{"error":"not found"}'

clean:
	rm -rf $(BUILD_DIR)
