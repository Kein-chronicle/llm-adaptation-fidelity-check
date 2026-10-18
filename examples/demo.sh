#!/usr/bin/env bash
cd "$(dirname "$0")/.."
run() { printf '$ %s\n' "$*"; "$@"; printf '[exit %s]\n\n' "$?"; }
echo "# A faithful adaptation of a source text"
run python3 scripts/check_fidelity.py tests/fixtures/good.json tests/fixtures/source.txt
echo "# A quote the adaptation altered, and a number it invented"
run python3 scripts/check_fidelity.py tests/fixtures/bad_quote.json tests/fixtures/source.txt
run python3 scripts/check_fidelity.py tests/fixtures/bad_number.json tests/fixtures/source.txt
echo "# Banned phrases are caught outside quotes but allowed inside them"
tmp=.demo-tmp; rm -rf "$tmp"; mkdir "$tmp"; trap 'rm -rf "$tmp"' EXIT
printf 'It is being done by us.\n' > "$tmp/bad.txt"; printf 'The author says "it is being done" here.\n' > "$tmp/ok.txt"
run python3 scripts/style_lint.py "$tmp/bad.txt" --ban "is being done"
run python3 scripts/style_lint.py "$tmp/ok.txt" --ban "is being done"
