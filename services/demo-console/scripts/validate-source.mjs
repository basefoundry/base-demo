import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const serviceDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const packageJson = readJson(resolve(serviceDir, "package.json"));
const declaredPackages = {
  ...(packageJson.dependencies || {}),
  ...(packageJson.devDependencies || {})
};
assert(declaredPackages.react, "package.json must declare react");
assert(declaredPackages.vite, "package.json must declare vite");

for (const file of ["index.html", "vite.config.js", "src/main.jsx", "src/App.jsx", "src/App.css"]) {
  assert(existsSync(resolve(serviceDir, file)), `${file} is missing`);
}

const appSource = readFileSync(resolve(serviceDir, "src", "App.jsx"), "utf8");
assert(appSource.includes("service-catalog.json"), "App must load the service catalog");
assert(appSource.includes("Base Demo Console"), "App must render the console title");

const catalog = readJson(resolve(serviceDir, "public", "service-catalog.json"));
const services = catalog.services || [];
const names = new Set(services.map((service) => service.name));
for (const name of ["go-api", "python-api", "java-gradle-api", "java-maven-api", "c-service", "cpp-service", "demo-console"]) {
  assert(names.has(name), `catalog missing ${name}`);
}

console.log(`demo-console catalog contains ${services.length} services.`);
