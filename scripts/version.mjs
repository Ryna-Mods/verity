#!/usr/bin/env node
// The addon's version and API level, read from its TOC (the one place they are written), and held
// to the tag when there is one.
//
//   node scripts/version.mjs [--tag vX.Y.Z]     prints version=X.Y.Z and api=N
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const toc = readFileSync(join(root, "Ryna_Verity", "Ryna_Verity.toc"), "utf8");
const field = (key) => new RegExp(`^## ${key}:\\s*(\\S+)\\s*$`, "m").exec(toc)?.[1];
const version = field("Version");
const api = field("X-Ryna-API");
if (!/^\d+\.\d+\.\d+$/.test(version ?? "")) throw new Error(`the TOC's version isn't X.Y.Z (${version})`);
if (!/^[1-9]\d*$/.test(api ?? "")) throw new Error(`the TOC's X-Ryna-API isn't a level (${api})`);
if (!/^## Dependencies:\s*Ryna_Core\s*$/m.test(toc)) throw new Error("the TOC doesn't depend on Ryna_Core");
const at = process.argv.indexOf("--tag");
if (at > 0) {
  if (process.argv[at + 1] !== `v${version}`) throw new Error(`the tag is ${process.argv[at + 1]}, the TOC says ${version}`);
}
console.log(`version=${version}\napi=${api}`);
