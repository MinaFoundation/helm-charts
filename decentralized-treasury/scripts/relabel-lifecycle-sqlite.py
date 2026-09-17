#!/usr/bin/env python3
"""Relabels one lifecycle's sqlite body so it answers for another lifecycle id.

    relabel-lifecycle-sqlite.py <db> <source-id> <target-id>

Every row inside a body is namespaced with the lifecycle id that produced it
("staking-ledger-42-accounts:7", "voting-ledger-42-merkle-tree:3-12",
"staking-ledger-to-voting-ledger-proof-42:1", ...), so a body cannot be shared
between lifecycle ids by file name alone: a service started for lifecycle 59
against 42's body finds none of its own keys, serves an empty ledger, and
every proposal in that lifecycle then fails the staking ledger root check.
This rewrites the namespaces instead, leaving the part of each key after the
":" untouched.

Run it on a copy, never on the canonical body - it rewrites in place.
"""

import os
import sqlite3
import sys
import time

SUFFIX = ".sqlite"


def namespaces(connection, source_id):
    rows = connection.execute(
        "select substr(key,1,instr(key,':')-1) ns, count(*) c "
        "from keyv group by ns order by c"
    ).fetchall()
    return [
        (ns, count)
        for ns, count in rows
        if f"-{source_id}-" in ns or ns.endswith(f"-{source_id}")
    ]


def relabel(ns, source_id, target_id):
    if ns.endswith(f"-{source_id}"):
        return f"{ns[: -len(source_id)]}{target_id}"
    return ns.replace(f"-{source_id}-", f"-{target_id}-")


def main(db_path, source_id, target_id):
    connection = sqlite3.connect(db_path)
    # This runs on a throwaway copy, so a crash costs a re-download rather
    # than data: skip the rollback journal and the fsyncs to keep the rewrite
    # to minutes rather than hours.
    connection.execute("pragma journal_mode=off")
    connection.execute("pragma synchronous=off")
    connection.execute("pragma temp_store=memory")
    connection.execute("pragma cache_size=-262144")

    pending = namespaces(connection, source_id)
    if not pending:
        sys.exit(f"no namespace in {db_path} carries lifecycle id {source_id}")

    print(f"[relabel] {db_path}: lifecycle {source_id} -> {target_id}", flush=True)
    for ns, count in pending:
        target = relabel(ns, source_id, target_id)
        started_at = time.monotonic()
        # A range scan over the primary key, so each statement touches only
        # its own namespace instead of scanning the whole table.
        cursor = connection.execute(
            "update keyv set key = ? || substr(key, ?) where key >= ? and key < ?",
            (target, len(ns) + 1, f"{ns}:", f"{ns};"),
        )
        elapsed = time.monotonic() - started_at
        print(
            f"[relabel]   {ns} -> {target}: "
            f"{cursor.rowcount}/{count} rows in {elapsed:.1f}s",
            flush=True,
        )
    connection.commit()

    leftover = connection.execute(
        "select count(*) from keyv where substr(key,1,instr(key,':')-1) like ?",
        (f"%{source_id}%",),
    ).fetchone()[0]
    accounts = connection.execute(
        "select count(*) from keyv where key like ?",
        (f"staking-ledger-{target_id}-accounts:%",),
    ).fetchone()[0]
    first_account = connection.execute(
        "select 1 from keyv where key = ?",
        (f"staking-ledger-{target_id}-accounts:0",),
    ).fetchone()
    connection.close()

    print(
        f"[relabel] namespaces still naming {source_id}: {leftover}, "
        f"staking-ledger-{target_id}-accounts rows: {accounts}, "
        f"index 0 present: {'yes' if first_account else 'no'}",
        flush=True,
    )
    if leftover or not accounts or not first_account:
        sys.exit("[relabel] incomplete - do not publish this body")
    print("[relabel] done", flush=True)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    db, source, target = sys.argv[1], sys.argv[2], sys.argv[3]
    if not os.path.isfile(db):
        sys.exit(f"{db} does not exist")
    if not source.isdigit() or not target.isdigit():
        sys.exit("source and target lifecycle ids must be decimal integers")
    main(db, source, target)
