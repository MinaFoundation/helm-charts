#!/usr/bin/env python3
"""Writes a new lifecycle body from an existing one, under another lifecycle id.

    relabel-lifecycle-sqlite.py <source-db> <output-db> <source-id> <target-id>

Every row inside a body is namespaced with the lifecycle id that produced it
("staking-ledger-42-accounts:7", "voting-ledger-42-merkle-tree:3-12",
"staking-ledger-to-voting-ledger-proof-42:1", ...), so a body cannot be shared
between lifecycle ids by file name alone: a service started for lifecycle 59
against 42's body finds none of its own keys, serves an empty ledger, and
every proposal in that lifecycle then fails the staking ledger root check.
This writes the same rows out under the target id's namespaces, leaving the
part of each key after the ":" untouched.

It builds a fresh file rather than rewriting a copy in place. An in-place
UPDATE moves every primary key entry within one b-tree - measured at over 45
minutes for the ~15.6M rows of one voting ledger's merkle tree, against under
two minutes here - because inserting namespace by namespace, in ascending
order of the new name, appends to the b-tree instead of churning it.
"""

import os
import sqlite3
import sys
import time

# Same DDL as the producer writes, so a relabelled body reads back exactly as
# a natively built one does.
KEYV_DDL = "CREATE TABLE keyv(key VARCHAR(255) PRIMARY KEY, value TEXT )"
CHECKPOINT_META_DDL = (
    "CREATE TABLE checkpoint_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)"
)


def relabel(ns, source_id, target_id):
    if ns.endswith(f"-{source_id}"):
        return f"{ns[: -len(source_id)]}{target_id}"
    return ns.replace(f"-{source_id}-", f"-{target_id}-")


def namespaces(connection, source_id, target_id):
    rows = connection.execute(
        "select substr(key,1,instr(key,':')-1) ns, count(*) c "
        "from src.keyv group by ns"
    ).fetchall()
    pending = [
        (ns, count, relabel(ns, source_id, target_id))
        for ns, count in rows
        if f"-{source_id}-" in ns or ns.endswith(f"-{source_id}")
    ]
    # Ascending by the name being written, so the inserts below only ever
    # append to the output's primary key index.
    return sorted(pending, key=lambda row: row[2])


def main(source_db, output_db, source_id, target_id):
    connection = sqlite3.connect(output_db)
    # The output is disposable until it is verified and published, so trade
    # durability for speed.
    connection.execute("pragma journal_mode=off")
    connection.execute("pragma synchronous=off")
    connection.execute("pragma cache_size=-262144")
    connection.execute(f"attach database '{source_db}' as src")
    connection.execute(KEYV_DDL)
    connection.execute(CHECKPOINT_META_DDL)
    connection.execute(
        "insert into checkpoint_meta select key, value from src.checkpoint_meta"
    )

    pending = namespaces(connection, source_id, target_id)
    if not pending:
        sys.exit(f"no namespace in {source_db} carries lifecycle id {source_id}")

    print(
        f"[relabel] {output_db} from {source_db}: {source_id} -> {target_id}",
        flush=True,
    )
    for ns, count, target in pending:
        started_at = time.monotonic()
        cursor = connection.execute(
            "insert into keyv(key, value) "
            "select ? || substr(key, ?), value from src.keyv "
            "where key >= ? and key < ?",
            (target, len(ns) + 1, f"{ns}:", f"{ns};"),
        )
        elapsed = time.monotonic() - started_at
        print(
            f"[relabel]   {target}: {cursor.rowcount}/{count} rows "
            f"in {elapsed:.1f}s",
            flush=True,
        )
    connection.commit()

    expected = connection.execute("select count(*) from src.keyv").fetchone()[0]
    actual = connection.execute("select count(*) from keyv").fetchone()[0]
    leftover = connection.execute(
        "select count(*) from keyv where substr(key,1,instr(key,':')-1) like ?",
        (f"%{source_id}%",),
    ).fetchone()[0]
    first_account = connection.execute(
        "select 1 from keyv where key = ?",
        (f"staking-ledger-{target_id}-accounts:0",),
    ).fetchone()
    connection.execute("detach database src")
    connection.close()

    print(
        f"[relabel] rows {actual}/{expected}, namespaces still naming "
        f"{source_id}: {leftover}, index 0 present: "
        f"{'yes' if first_account else 'no'}",
        flush=True,
    )
    if actual != expected or leftover or not first_account:
        sys.exit("[relabel] incomplete - do not publish this body")
    print("[relabel] done", flush=True)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    source_db, output_db, source, target = sys.argv[1:5]
    if not os.path.isfile(source_db):
        sys.exit(f"{source_db} does not exist")
    if os.path.exists(output_db):
        sys.exit(f"{output_db} already exists - remove it first")
    if not source.isdigit() or not target.isdigit():
        sys.exit("source and target lifecycle ids must be decimal integers")
    main(source_db, output_db, source, target)
