# copyright None
# author Matthieu GOSSET
# maintainers Matthieu GOSSET <matthieu.gosset.dev@chapsvision.com>
# purpose make targets

DUNE=dune
CC=$(DUNE)
BUILD=$(CC) build
EXEC=$(CC) exec --profile=release
TEST_FIFO?=tests/test_fifo

.PHONY: all demo tests

all:
	$(BUILD)

bin/demo.exe:
	$(BUILD) $@

demo: bin/demo.exe
	$(EXEC) $< $(TEST_FIFO)

tests/tests.exe:
	$(BUILD) $@

tests: tests/tests.exe
	$(EXEC) $< $(TEST_FIFO)

help:
	cat README.md