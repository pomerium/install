// Validates a staged OpenAI plugin bundle: plugin.json and mcp.json against
// the official Agent Plugins schemas, plugin.json against OpenAI's submission
// requirements, and that every image the listing references is in the bundle.
//
// Usage: node validate-openai-bundle.mjs <bundle-dir> <agent-plugins-schema-dir>
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import Ajv2020 from "ajv/dist/2020.js";

const [bundleDir, schemaDir] = process.argv.slice(2);
if (!bundleDir || !schemaDir) {
  console.error("usage: validate-openai-bundle.mjs <bundle-dir> <agent-plugins-schema-dir>");
  process.exit(2);
}

const readJSON = (path) => JSON.parse(readFileSync(path, "utf8"));
const ajv = new Ajv2020({ allErrors: true });
const errors = [];

function check(schemaPath, dataPath) {
  const validate = ajv.compile(readJSON(schemaPath));
  if (!validate(readJSON(dataPath))) {
    for (const e of validate.errors) {
      errors.push(`${dataPath}${e.instancePath}: ${e.message} (${schemaPath})`);
    }
  }
}

const pluginPath = join(bundleDir, "plugin.json");
check(join(schemaDir, "plugin.schema.json"), pluginPath);
check(join(schemaDir, "mcp.schema.json"), join(bundleDir, "mcp.json"));
check(join(dirname(fileURLToPath(import.meta.url)), "openai-submission.schema.json"), pluginPath);

const listing = readJSON(pluginPath).extensions?.["com.openai"]?.interface ?? {};
const images = [listing.logo, listing.logoDark, listing.composerIcon, listing.composerIconDark, ...(listing.screenshots ?? [])];
for (const image of images) {
  if (image && !existsSync(join(bundleDir, image))) {
    errors.push(`${pluginPath}: ${image} is not in the bundle`);
  }
}

if (errors.length > 0) {
  console.error(errors.join("\n"));
  process.exit(1);
}
console.log(`${bundleDir}: OpenAI bundle is valid`);
