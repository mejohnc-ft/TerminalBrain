.PHONY: help build install verify live ask ask-commit snapshot snapshot-json snapshot-brief snapshot-brief-md snapshot-today snapshot-blindspots snapshot-ideas snapshot-projects snapshot-deck snapshot-deck-md latest-pack handoff snapshot-file mcp-check mcp-test

help:
	@echo "Terminal Brain commands:"
	@echo "  make verify        Non-launching static QA"
	@echo "  make live          API/MCP QA against an already-running app"
	@echo "  make ask QUERY=... Ask Terminal Brain Oracle from an already-running app"
	@echo "  make ask-commit QUERY=... PROJECT=... Ask Oracle and commit the answer"
	@echo "  make build         Build the macOS app without launching it"
	@echo "  make install       Copy the app to ~/Applications without launching it"
	@echo "  make snapshot      Print Markdown snapshot from an already-running app"
	@echo "  make snapshot-json Print JSON snapshot from an already-running app"
	@echo "  make snapshot-brief Print Operator Brief JSON from an already-running app"
	@echo "  make snapshot-brief-md Print Operator Brief Markdown from an already-running app"
	@echo "  make snapshot-today Print Decision Lane Markdown from an already-running app"
	@echo "  make snapshot-blindspots Print Blindspot Brief Markdown from an already-running app"
	@echo "  make snapshot-ideas Print Idea Pulse Markdown from an already-running app"
	@echo "  make snapshot-projects Print Project Memory Markdown from an already-running app"
	@echo "  make snapshot-deck Print Operator Deck JSON from an already-running app"
	@echo "  make snapshot-deck-md Print Operator Deck Markdown from an already-running app"
	@echo "  make latest-pack   Print latest context pack Markdown from an already-running app"
	@echo "  make handoff OUTPUT=/tmp/terminal-brain-handoff.md"
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

ask:
	@if test -z "$$QUERY"; then echo "Set QUERY='question to ask'" >&2; exit 64; fi
	./mac-app/scripts/oracle.zsh "$$QUERY"

ask-commit:
	@if test -z "$$QUERY"; then echo "Set QUERY='question to ask'" >&2; exit 64; fi
	@if test -n "$$PROJECT"; then ./mac-app/scripts/oracle.zsh --commit --project "$$PROJECT" "$$QUERY"; else ./mac-app/scripts/oracle.zsh --commit "$$QUERY"; fi

snapshot:
	./mac-app/scripts/snapshot.zsh --markdown

snapshot-json:
	./mac-app/scripts/snapshot.zsh --json

snapshot-brief:
	./mac-app/scripts/snapshot.zsh --brief

snapshot-brief-md:
	./mac-app/scripts/snapshot.zsh --brief-markdown

snapshot-today:
	./mac-app/scripts/snapshot.zsh --today

snapshot-blindspots:
	./mac-app/scripts/snapshot.zsh --blindspots

snapshot-ideas:
	./mac-app/scripts/snapshot.zsh --ideas

snapshot-projects:
	./mac-app/scripts/snapshot.zsh --projects

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
