// Blocks until the database has applied every migration shipped in this image.
//
// This is the decentralized-treasury counterpart to mina-archive's
// wait-for-db.sh. Every workload that reads the schema runs it as an init
// container, so the api-migrate Job and all of its dependents can be applied at
// once and still converge in the right order - no Helm hooks, no imperative
// ordering step.
//
// Both halves of the comparison come from the image itself, so nothing has to
// be hardcoded in values and nothing drifts when a migration is added:
//
//   shipped = highest timestamp prefix under apps/api/src/db/migrations/
//   applied = max("timestamp") in TypeORM's migrations table
//
// TypeORM inserts one row per migration, each in its own transaction and in
// ascending timestamp order, so the highest applied timestamp only reaches the
// shipped value once the whole run has finished.

import { readdirSync } from "node:fs";
import { join } from "node:path";
import { API_DIRECTORY, log, pollUntilReady } from "./pg-wait.mjs";

const MIGRATIONS_DIRECTORY = join(API_DIRECTORY, "src", "db", "migrations");
const MIGRATIONS_TABLE = process.env.MIGRATIONS_TABLE ?? "migrations";
const DATABASE_SCHEMA = process.env.DATABASE_SCHEMA ?? "public";

// TypeORM names migration files `<timestamp>-<description>.ts`.
const TIMESTAMP_PREFIX = /^(\d+)-/;

function shippedTimestamp() {
  const timestamps = readdirSync(MIGRATIONS_DIRECTORY)
    .map((file) => TIMESTAMP_PREFIX.exec(file)?.[1])
    .filter(Boolean)
    .map(Number);

  if (timestamps.length === 0) {
    throw new Error(`No migrations found in ${MIGRATIONS_DIRECTORY}`);
  }
  return Math.max(...timestamps);
}

function quoteIdentifier(identifier) {
  return `"${identifier.replace(/"/g, '""')}"`;
}

const shipped = shippedTimestamp();
const table = `${quoteIdentifier(DATABASE_SCHEMA)}.${quoteIdentifier(MIGRATIONS_TABLE)}`;

// Before api-migrate has run for the first time the migrations table does not
// exist yet; that query error is caught upstream and treated as "not ready".
await pollUntilReady(`migrations through ${shipped} to be applied`, async (client) => {
  const { rows } = await client.query(`SELECT max("timestamp") AS applied FROM ${table}`);
  const applied = Number(rows[0]?.applied ?? 0);
  log(`applied=${applied} shipped=${shipped}`);
  return applied >= shipped;
});
