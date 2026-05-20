.PHONY: help build install verify live snapshot snapshot-json snapshot-deck snapshot-deck-md latest-pack handoff snapshot-file mcp-check mcp-test

help:
	@echo "Terminal Brain commands:"
	@echo "  make verify        Non-launching static QA"
	@echo "  make live          API/MCP QA against an already-running app"
	@echo "  make build         Build the macOS app without launching it"
	@echo "  make install       Copy the app to ~/Applications without launching it"
	@echo "  make snapshot      Print Markdown snapshot from an already-running app"
	@echo "  make snapshot-json Print JSON snapshot from an already-running app"
	@echo "  make snapshot-deck Print Operator Deck JSON from an already-running app"
	@echo "  make snapshot-deck-md Print Operator Deck Markdown from an already-running app"
	@echo "  make latest-pack   Print latest context pack Markdown from an already-running app"
	@echo "  make handoff       Write deck + latest pack handoff Markdown"
	@echo "  make snapshot-file OUTPUT=/tmp/terminal-brain-snapshot.md"
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

snapshot-deck:
	./mac-app/scripts/snapshot.zsh --deck

snapshot-deck-md:
	./mac-app/scripts/snapshot.zsh --deck-markdown

latest-pack:
	./mac-app/scripts/snapshot.zsh --latest-pack

handoff:
	./mac-app/scripts/handoff.zsh

snapshot-file:
	@if test -z "$$OUTPUT"; then echo "Set OUTPUT=/path/to/snapshot.md" >&2; exit 64; fi
	./mac-app/scripts/snapshot.zsh --markdown --output "$$OUTPUT"

mcp-check:
	cd mcp-server && npm run check

mcp-test:
	cd mcp-server && npm test
