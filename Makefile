# copyright None
# author Matthieu GOSSET
# maintainers Matthieu GOSSET <matthieu.gosset.dev@chapsvision.com>
# purpose make targets

DUNE=dune
CC=$(DUNE)
BUILD=$(CC) build
EXEC=$(CC) exec --profile=release
RUN=_build/default/
TEST_FIFO?=tests/test_fifo

PATH_TEST=tests
TEST_BIN=tests.exe

PATH_DEMO=bin/demo
DEMO_BIN=demo.exe

PATH_CLIENT=bin/client-server
CLIENT_BIN=client.exe
PATH_SERVER=bin/client-server
SERVER_BIN=server.exe

.PHONY: all demo tests client-server

all:
	$(BUILD)

$(PATH_CLIENT)/$(CLIENT_BIN):
	$(BUILD) $@

$(PATH_SERVER)/$(SERVER_BIN):
	$(BUILD) $@

client-server: $(PATH_CLIENT)/$(CLIENT_BIN) $(PATH_SERVER)/$(SERVER_BIN)
	$(RUN)/$(PATH_SERVER)/$(SERVER_BIN) $(TEST_FIFO)_2 $(TEST_FIFO)_1 & \
	sleep 2 && \
	$(RUN)/$(PATH_CLIENT)/$(CLIENT_BIN) $(TEST_FIFO)_1 $(TEST_FIFO)_2

$(PATH_DEMO)/$(DEMO_BIN):
	$(BUILD) $@

demo: $(PATH_DEMO)/$(DEMO_BIN)
	$(EXEC) $< $(TEST_FIFO)

$(PATH_TEST)/$(TEST_BIN):
	$(BUILD) $@

tests: $(PATH_TEST)/$(TEST_BIN)
	$(EXEC) $< $(TEST_FIFO)

help:
	cat README.md