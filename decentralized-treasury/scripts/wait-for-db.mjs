// Blocks until Postgres accepts connections.
//
// Used as an init container on the api-migrate Job so that a database which is
// still starting up shows up as a wait with clear logs, rather than burning
// through the Job's backoffLimit on connection-refused errors.

import { pollUntilReady } from "./pg-wait.mjs";

await pollUntilReady("Postgres to accept connections", async (client) => {
  await client.query("SELECT 1");
  return true;
});
