#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

ruby -rjson -e '
  root = ARGV.fetch(0)
  expected = JSON.parse(File.read(File.join(root, "mac-app", "expected-api-routes.json"))).sort
  source = File.read(File.join(root, "mac-app", "Sources", "TerminalBrain", "LocalControlServer.swift"))
  actual = source.scan(/case \("([A-Z]+)", "([^"]+)"\):/).map { |method, path| "#{method} #{path}" }.sort
  missing = expected - actual
  unexpected = actual - expected
  unless missing.empty? && unexpected.empty?
    warn "Missing API routes: #{missing.join(", ")}" unless missing.empty?
    warn "Unexpected API routes: #{unexpected.join(", ")}" unless unexpected.empty?
    exit 1
  end
  puts "api routes ok count=#{actual.length}"
' "$ROOT"
