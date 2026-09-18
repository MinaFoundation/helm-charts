#!/usr/bin/env bash
# Exercises s3-sync-pull.sh against a fake bucket. Run it from anywhere:
#
#   ./tests/pull-sync.sh
#
# `aws` is stubbed so the script runs unmodified - the "bucket" is a directory.
#
# What it pins down:
#   * a body truncated by an interrupted download is refetched. The size check
#     that decides this compares against the exact <id>.sqlite key; `aws s3 ls`
#     matches by prefix, so reading any listed line's size reported a marker's
#     handful of bytes as the body size and the check never fired.
#   * a .done marker with no body behind it is skipped, not chased into an
#     `aws s3 cp` that 404s and ends the cycle under `set -eu`.
#   * SQLITE_PULL_BODIES=false fetches markers and no bodies, which is what a
#     producer wants.
set -euo pipefail

CHART="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT=$(mktemp -d)
BUCKET="$ROOT/bucket"
BIN="$ROOT/bin"
mkdir -p "$BUCKET" "$BIN"

# Bodies for 7 and 8; 9 has a marker and no body at all.
#
# The bodies are deliberately much larger than the markers, and the truncated
# local copy below larger still: that is the real shape (a 173-byte marker
# beside a multi-GB database), and it is what makes the prefix-matching bug
# visible. With a body smaller than its own marker the broken comparison
# happens to give the right answer.
python3 -c "import sys; sys.stdout.write('7' * 20000)" > "$BUCKET/7.sqlite"
python3 -c "import sys; sys.stdout.write('8' * 20000)" > "$BUCKET/8.sqlite"
for id in 7 8 9; do
  printf '{"lifecycleId":"%s"}' "$id" > "$BUCKET/$id.sqlite.done"
  printf '{"lifecycleId":"%s"}' "$id" > "$BUCKET/$id.sqlite.proven"
done

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

export PATH="$BIN:$PATH"
export SQLITE_S3_BUCKET=test-bucket NETWORK=devnet SYNC_ONESHOT=true SQLITE_KEEP_LAST_N=0

fail=0
check() { if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1: expected '$3', got '$2'"; fail=1; fi; }

echo "=== consumer: truncated body is refetched, bodiless marker is skipped ==="
DATA="$ROOT/consumer"; mkdir -p "$DATA"
# A copy pulled while it was still being written: short of the remote body,
# but far larger than any marker beside it.
python3 -c "import sys; sys.stdout.write('7' * 5000)" > "$DATA/7.sqlite"
SQLITE_DATA_DIRECTORY="$DATA" sh "$CHART/scripts/s3-sync-pull.sh" > "$ROOT/consumer.log" 2>&1 || {
  echo "  FAIL the sync exited non-zero:"; sed 's/^/     /' "$ROOT/consumer.log"; fail=1; }
check "truncated body 7 refetched" "$(wc -c < "$DATA/7.sqlite" 2>/dev/null | tr -d ' ')" 20000
check "whole body 8 fetched" "$(wc -c < "$DATA/8.sqlite" 2>/dev/null | tr -d ' ')" 20000
check "bodiless id 9 skipped" "$([ -f "$DATA/9.sqlite" ] && echo present || echo absent)" absent
if grep -q "no body in" "$ROOT/consumer.log"; then echo "  ok   logged the bodiless marker"; else echo "  FAIL no log line for id 9"; fail=1; fi

echo
echo "=== producer: markers only ==="
PDATA="$ROOT/producer"; mkdir -p "$PDATA"
SQLITE_DATA_DIRECTORY="$PDATA" SQLITE_PULL_BODIES=false \
  sh "$CHART/scripts/s3-sync-pull.sh" > "$ROOT/producer.log" 2>&1
if grep -q "markers only" "$ROOT/producer.log"; then echo "  ok   took the markers-only path"; else echo "  FAIL no markers-only log line"; fail=1; fi
check "fetched no bodies" "$(find "$PDATA" -maxdepth 1 -name '*.sqlite' | wc -l | tr -d ' ')" 0
check "fetched the markers" "$(find "$PDATA" -maxdepth 1 -name '*.sqlite.done' | wc -l | tr -d ' ')" 3

echo
[ "$fail" = 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
rm -rf "$ROOT"
exit "$fail"
