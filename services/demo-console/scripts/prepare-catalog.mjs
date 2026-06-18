import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const serviceDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(serviceDir, "..", "..");
const source = resolve(repoRoot, "services", "catalog.json");
const destinationDir = resolve(serviceDir, "public");
const destination = resolve(destinationDir, "service-catalog.json");

mkdirSync(destinationDir, { recursive: true });
copyFileSync(source, destination);
console.log(`demo-console catalog synced from ${source}`);
