build: ; ./build.sh

# for originally generating the .fnl files
# SRC := $(shell find data -name "*.lua")
# OUT := $(patsubst %.lua,%.fnl,$(SRC))
# %.fnl: %.lua ; antifennel $< > $@
# antifennel: $(OUT)
