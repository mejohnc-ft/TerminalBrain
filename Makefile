.PHONY: help build install verify live snapshot snapshot-json mcp-check mcp-test

help:
	@echo "Terminal Brain commands:"
	@echo "  make verify        Non-launching static QA"
	@echo "  make live          API/MCP QA against an already-running app"
	@echo "  make build         Build the macOS app without launching it"
	@echo "  make install       Copy the app to ~/Applications without launching it"
	@echo "  make snapshot      Print Markdown snapshot from an already-running app"
	@echo "  make snapshot-json Print JSON snapshot from an already-running app"
	@echo "  make mcp-check     Check MCP server syntax"
	@echo "  make mcp-test      Check MCP tool contract"

build:
	./mac-app/scripts/build-app.zsh

install:
	./mac-app/scripts/install-app.zsh

verify:
	./mac-app/scripts/verify-static.zsh

live:
	./mac-app/scripts/verify-live.zsh

snapshot:
	./mac-app/scripts/snapshot.zsh --markdown

snapshot-json:
	./mac-app/scripts/snapshot.zsh --json

mcp-check:
	cd mcp-server && npm run check

mcp-test:
	cd mcp-server && npm test
