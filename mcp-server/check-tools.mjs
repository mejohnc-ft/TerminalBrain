#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const root = dirname(fileURLToPath(import.meta.url));
const expected = JSON.parse(await readFile(join(root, "expected-tools.json"), "utf8"));

const child = spawn(process.execPath, [join(root, "server.mjs")], {
  stdio: ["pipe", "pipe", "inherit"]
});

let output = "";
child.stdout.setEncoding("utf8");
child.stdout.on("data", (chunk) => {
  output += chunk;
});

child.stdin.write(JSON.stringify({
  jsonrpc: "2.0",
  id: 1,
  method: "tools/list",
  params: {}
}) + "\n");
child.stdin.end();

const timeout = setTimeout(() => {
  child.kill("SIGTERM");
  console.error("Timed out waiting for MCP tools/list response.");
  process.exit(1);
}, 3000);

const exitCode = await new Promise((resolve) => {
  child.on("exit", resolve);
});
clearTimeout(timeout);

if (exitCode !== 0) {
  console.error(`MCP server exited with code ${exitCode}.`);
  process.exit(1);
}

const line = output.split("\n").find((entry) => entry.includes('"result"'));
if (!line) {
  console.error("No tools/list result returned.");
  process.exit(1);
}

const response = JSON.parse(line);
const tools = response?.result?.tools ?? [];
const actual = tools.map((tool) => tool.name).sort();
const wanted = [...expected].sort();
const missing = wanted.filter((name) => !actual.includes(name));
const unexpected = actual.filter((name) => !wanted.includes(name));

if (missing.length || unexpected.length) {
  if (missing.length) console.error(`Missing tools: ${missing.join(", ")}`);
  if (unexpected.length) console.error(`Unexpected tools: ${unexpected.join(", ")}`);
  process.exit(1);
}

console.log(`mcp tools ok count=${actual.length}`);
