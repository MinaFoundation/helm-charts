// Shared polling helpers for the wait-for-* init container scripts.
//
// These files are mounted from a ConfigMap at /scripts, which sits outside the
// pnpm workspace, so `pg` has to be resolved from the api workspace explicitly
// rather than through the usual node_modules lookup. The .mjs extension is
// deliberate: there is no package.json above /scripts, so Node would otherwise
// treat a plain .js file as CommonJS.

import { createRequire } from "node:module";
import { join } from "node:path";

export const API_DIRECTORY = process.env.API_DIRECTORY ?? "/app/apps/api";

const require = createRequire(join(API_DIRECTORY, "package.json"));
const { Client } = require("pg");

const DEFAULT_POLL_INTERVAL_SECONDS = 5;
const DEFAULT_TIMEOUT_SECONDS = 600;
const CONNECTION_TIMEOUT_MS = 5000;

export function log(message) {
  console.log(`INFO: ${message}`);
}

function readPositiveSeconds(name, fallback) {
  const parsed = Number(process.env[name]);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

const pollIntervalMs =
  readPositiveSeconds("WAIT_POLL_INTERVAL_SECONDS", DEFAULT_POLL_INTERVAL_SECONDS) * 1000;
const timeoutMs = readPositiveSeconds("WAIT_TIMEOUT_SECONDS", DEFAULT_TIMEOUT_SECONDS) * 1000;

function databaseUrl() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("Missing required environment variable: DATABASE_URL");
  }
  return url;
}

// Every attempt uses a fresh connection so that a database which restarts
// mid-wait does not leave us polling a dead socket. Any failure - refused
// connection, missing table, permission error - is reported as "not ready"
// so the caller keeps waiting instead of crashing the init container.
async function attempt(probe) {
  const client = new Client({
    connectionString: databaseUrl(),
    connectionTimeoutMillis: CONNECTION_TIMEOUT_MS,
  });
  try {
    await client.connect();
    return await probe(client);
  } catch (error) {
    log(`not ready: ${error.message}`);
    return false;
  } finally {
    await client.end().catch(() => {});
  }
}

/** Polls `probe` until it reports ready, or exits non-zero once the timeout elapses. */
export async function pollUntilReady(description, probe) {
  const deadline = Date.now() + timeoutMs;
  log(`Waiting for ${description}`);

  while (Date.now() < deadline) {
    if (await attempt(probe)) {
      log(`Ready: ${description}`);
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
  }

  console.error(`ERROR: timed out after ${timeoutMs / 1000}s waiting for ${description}`);
  process.exit(1);
}
