#!/usr/bin/env bash
# Exercises s3-sync-pull.sh's grouped-lifecycle path (lifecycleFanout in
# values.yaml) against a fake bucket. Run it from anywhere:
#
#   ./tests/pull-grouped-lifecycles.sh
#
# `aws` and `curl` are stubbed so both scripts run unmodified: the "bucket" is
# a directory, and the daemon reports a slot that puts the chain in lifecycle
# 59 of a groupSize-21 release, whose canonical is 42.
#
# What it pins down:
#   * the group's canonical is fetched, and its siblings are relabelled from it
#   * a sibling's rows carry its own namespace, with none of the canonical's
#   * a canonical built a group ahead of the chain is NOT fetched (it would
#     evict the one the current lifecycle needs)
#   * .done markers with no body behind them are skipped, not chased
#   * materialised siblings outside the window are pruned with their pointers
#   * nothing materialised locally is ever pushed to the bucket
set -euo pipefail

CHART="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT=$(mktemp -d)
BUCKET="$ROOT/bucket"
DATA="$ROOT/data"
BIN="$ROOT/bin"
mkdir -p "$BUCKET" "$DATA" "$BIN"

# --- fixture bucket: canonical 42 has a real body; 43..58 have orphan markers
python3 - "$BUCKET" <<'PY'
import sqlite3, sys, pathlib
bucket = pathlib.Path(sys.argv[1])
db = sqlite3.connect(bucket / "42.sqlite")
db.execute("CREATE TABLE keyv(key VARCHAR(255) PRIMARY KEY, value TEXT )")
db.execute("CREATE TABLE checkpoint_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
db.execute("insert into checkpoint_meta values('ledgerHash','jwrKGDuSyk')")
rows = [(f"staking-ledger-42-accounts:{i}", f"acct{i}") for i in range(50)]
rows += [(f"voting-ledger-42-merkle-tree:{i}-{i}", "field") for i in range(50)]
rows += [("staking-ledger-to-voting-ledger-proof-42:1", "proof")]
db.executemany("insert into keyv values(?,?)", rows)
db.commit(); db.close()
(bucket / "42.sqlite.done").write_text('{"lifecycleId":"42"}')
(bucket / "42.sqlite.proven").write_text('{"lifecycleId":"42"}')
# a newer canonical, built a group ahead of the chain: nothing needs it yet
import shutil
shutil.copy(bucket / "42.sqlite", bucket / "63.sqlite")
(bucket / "63.sqlite.done").write_text('{"lifecycleId":"63"}')
(bucket / "63.sqlite.proven").write_text('{"lifecycleId":"63"}')
# orphan markers with no body, exactly as devnet has for 43..58
for i in list(range(43, 59)):
    (bucket / f"{i}.sqlite.done").write_text('{"lifecycleId":"%d"}' % i)
    (bucket / f"{i}.sqlite.proven").write_text('{"lifecycleId":"%d"}' % i)
PY

# --- a stale materialised sibling from an earlier window, to prove it is pruned
cp "$BUCKET/42.sqlite" "$DATA/50.sqlite"
printf '42' > "$DATA/50.sqlite.sibling"

# --- stub aws
cat > "$BIN/aws" <<STUB
#!/usr/bin/env bash
set -euo pipefail
BUCKET="$BUCKET"
strip() { printf '%s' "\$1" | sed 's#^s3://[^/]*/[^/]*/*##'; }
case "\$2" in
  ls)
    key=\$(strip "\$3")
    for f in "\$BUCKET"/*; do
      [ -e "\$f" ] || continue
      name=\$(basename "\$f")
      case "\$name" in
        \${key}*) printf '2026-09-17 00:00:00 %s %s\n' "\$(wc -c < "\$f" | tr -d ' ')" "\$name" ;;
      esac
    done
    ;;
  cp)
    key=\$(strip "\$3")
    [ -f "\$BUCKET/\$key" ] || { echo "fatal error: 404 \$key" >&2; exit 1; }
    if [ "\$4" = "-" ]; then cat "\$BUCKET/\$key"; else cp "\$BUCKET/\$key" "\$4"; fi
    ;;
  sync)
    dest=\$(printf '%s' "\$4" | sed 's#/\$##')
    for f in "\$BUCKET"/*.sqlite.done "\$BUCKET"/*.sqlite.proven; do
      [ -e "\$f" ] || continue
      cp "\$f" "\$dest/"
    done
    ;;
esac
STUB
chmod +x "$BIN/aws"

# --- stub curl: slot 886760 with deployedAt 866700, period 85, 4 periods => lifecycle 59
cat > "$BIN/curl" <<'STUB'
#!/usr/bin/env bash
echo '{"data":{"bestChain":[{"protocolState":{"consensusState":{"slotSinceGenesis":"886800"}}}]}}'
STUB
chmod +x "$BIN/curl"

export PATH="$BIN:$PATH"
export SQLITE_DATA_DIRECTORY="$DATA"
export SQLITE_S3_BUCKET=test-bucket
export NETWORK=devnet
export SQLITE_KEEP_LAST_N=2
export SYNC_ONESHOT=true
export MATERIALISE_SIBLINGS=true
export LIFECYCLE_ANCHOR_GROUP_SIZE=21
export SIBLING_WINDOW_BEHIND=0
export SIBLING_WINDOW_AHEAD=1
export LIFECYCLE_PERIOD_DURATION=85
export PERIODS_PER_LIFECYCLE=4
export TREASURY_DEPLOYED_AT_SLOT=866700
export MINA_NODE_URL=http://fake/graphql
export RELABEL_SCRIPT="$CHART/scripts/relabel-lifecycle-sqlite.py"

echo "=== running s3-sync-pull.sh ==="
sh "$CHART/scripts/s3-sync-pull.sh"

echo
echo "=== local bodies after the cycle ==="
ls -1 "$DATA" | sort

echo
echo "=== assertions ==="
fail=0
check() { if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1: expected '$3', got '$2'"; fail=1; fi; }

check "canonical 42 fetched" "$([ -f "$DATA/42.sqlite" ] && echo yes || echo no)" yes
check "sibling 59 materialised" "$([ -f "$DATA/59.sqlite" ] && echo yes || echo no)" yes
check "sibling 60 materialised" "$([ -f "$DATA/60.sqlite" ] && echo yes || echo no)" yes
check "future canonical 63 not fetched" "$([ -f "$DATA/63.sqlite" ] && echo yes || echo no)" no
check "orphan 43 not fetched" "$([ -f "$DATA/43.sqlite" ] && echo yes || echo no)" no
check "orphan 58 not fetched" "$([ -f "$DATA/58.sqlite" ] && echo yes || echo no)" no
check "stale sibling 50 pruned" "$([ -f "$DATA/50.sqlite" ] && echo yes || echo no)" no
check "stale pointer 50 pruned" "$([ -f "$DATA/50.sqlite.sibling" ] && echo yes || echo no)" no
check "59 pointer names 42" "$(cat "$DATA/59.sqlite.sibling" 2>/dev/null)" 42

for id in 59 60; do
  got=$(python3 - "$DATA/$id.sqlite" "$id" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
n = db.execute("select count(*) from keyv where key like ?", (f"staking-ledger-{sys.argv[2]}-accounts:%",)).fetchone()[0]
stale = db.execute("select count(*) from keyv where key like '%-42-%' or key like '%-42:%'").fetchone()[0]
print(f"{n},{stale}")
PY
)
  check "sibling $id has its own namespace (rows,stale42)" "$got" "50,0"
done

echo
echo "=== push excludes ==="
export SOURCE_DIRECTORY="$DATA" S3_TARGET_PREFIX="s3://test-bucket/devnet"
export PUSH_PAYLOAD_INCLUDES='*.sqlite' PUSH_MARKER_INCLUDES='*.sqlite.done' SYNC_ONESHOT=true
cat > "$BIN/aws" <<'STUB'
#!/usr/bin/env bash
# Echo the sync arguments instead of uploading, so the excludes are visible.
[ "${2:-}" = "sync" ] && { shift 2; echo "AWS-SYNC-ARGS: $*"; }
exit 0
STUB
chmod +x "$BIN/aws"
timeout 10 sh -c "SYNC_INTERVAL_SECONDS=1 sh '$CHART/scripts/s3-sync-push.sh'" 2>&1 | head -6 > "$ROOT/push.log" || true
cat "$ROOT/push.log"
for id in 59 60; do
  if grep -q -- "--exclude $id.sqlite" "$ROOT/push.log"; then echo "  ok   sibling $id excluded from push"; else echo "  FAIL sibling $id NOT excluded"; fail=1; fi
done
if grep -q -- "--exclude 42.sqlite" "$ROOT/push.log"; then echo "  FAIL canonical 42 wrongly excluded"; fail=1; else echo "  ok   canonical 42 still publishable"; fi

echo
[ "$fail" = 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
rm -rf "$ROOT"
exit "$fail"
