.PHONY: build install verify snapshot snapshot-json mcp-check mcp-test

build:
	./mac-app/scripts/build-app.zsh

install:
	./mac-app/scripts/install-app.zsh

verify:
	./mac-app/scripts/verify-static.zsh

snapshot:
	./mac-app/scripts/snapshot.zsh --markdown

snapshot-json:
	./mac-app/scripts/snapshot.zsh --json

mcp-check:
	cd mcp-server && npm run check

mcp-test:
	cd mcp-server && npm test
