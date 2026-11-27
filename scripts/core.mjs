#!/usr/bin/env node
// Fetch the core addon the checks run against into .core/Ryna_Core: the oldest core this mod
// claims to work with (core.json, pinned by SHA-256). A mod's tests load the real core, so a mod
// that only works on a newer one fails here, before it is released.
//
//   node scripts/core.mjs
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const { oldest } = JSON.parse(readFileSync(join(root, "core.json"), "utf8"));
const dest = join(root, ".core");
const toc = join(dest, "Ryna_Core", "Ryna_Core.toc");
const stamp = join(dest, "sha256");

if (existsSync(toc) && existsSync(stamp) && readFileSync(stamp, "utf8") === oldest.sha256) {
  console.log(`Ryna_Core ${oldest.version} is already in .core/`);
  process.exit(0);
}
if (!/^https:\/\/github\.com\/(MaddisonM79\/ryna_agent|Ryna-Mods\/[a-z-]+)\/releases\/download\/[\w.-]+\/[\w.-]+\.zip$/.test(oldest.url)) {
  throw new Error(`core.json: ${oldest.url} isn't a release zip of the core`);
}
const res = await fetch(oldest.url, { redirect: "follow" });
if (!res.ok) throw new Error(`${oldest.url} answered ${res.status}`);
const bytes = Buffer.from(await res.arrayBuffer());
const sha = createHash("sha256").update(bytes).digest("hex");
if (sha !== oldest.sha256) throw new Error(`${oldest.url} isn't the file core.json pins (it is ${sha})`);

rmSync(dest, { recursive: true, force: true });
mkdirSync(dest, { recursive: true });
const zip = join(dest, "core.zip");
writeFileSync(zip, bytes);
execFileSync("unzip", ["-q", zip, "Ryna_Core/*", "-d", dest], { stdio: "inherit" });
rmSync(zip);
const version = /^## Version:\s*(\S+)/m.exec(readFileSync(toc, "utf8"))?.[1];
if (version !== oldest.version) throw new Error(`the zip's core is ${version}, core.json says ${oldest.version}`);
writeFileSync(stamp, sha);
console.log(`Ryna_Core ${version} is in .core/`);
