build: ; ./build.sh
count:
	cloc data src/api src/*.c src/*.h

# for originally generating the .fnl files
# SRC := $(shell find data -name "*.lua")
# OUT := $(patsubst %.lua,%.fnl,$(SRC))
# %.fnl: %.lua ; antifennel $< > $@
# antifennel: $(OUT)
