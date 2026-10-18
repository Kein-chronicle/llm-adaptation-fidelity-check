#!/usr/bin/env python3
"""Banned-phrase linter; text inside quotes is exempt (quotes are the source's words).
usage: style_lint.py file --ban PHRASE [--ban PHRASE ...]   exit 0 clean | 1 hits | 2 bad input
Matching is case-insensitive and ignores line breaks between words; offsets are character positions in the original file."""
import re, sys
args = sys.argv[1:]
if not args: print(__doc__); sys.exit(2)
f = args[0]; bans = [args[i+1] for i, a in enumerate(args) if a == "--ban" and i + 1 < len(args)]
if not bans: print("no --ban phrases given - an empty ruleset passes everything"); sys.exit(2)
try: txt = open(f, encoding="utf-8").read()
except (OSError, UnicodeError) as e: print(f"bad input: {type(e).__name__}"); sys.exit(2)
# Quoted spans (the source's own words) are blanked out with spaces of the SAME length, so reported offsets index the original text.
# An inch mark (5") is not an opening quote, and a quote cannot span more than 400 characters or a blank line.
def blank(m): return re.sub(r"[^\n]", " ", m.group(0))
txt_wo_quotes = re.sub(r"(?<!\d)[\"“「‘][^\"”」’\n]{0,400}[\"”」’]", blank, txt)
def phrase_re(b): return re.compile(r"\s+".join(re.escape(w) for w in b.split()), re.I)        # case-insensitive, any whitespace (even a line break) between words
hits = [(b, m.start()) for b in bans for m in phrase_re(b).finditer(txt_wo_quotes)]
for b, pos in hits: print(f"banned phrase {b!r} at offset {pos}")
sys.exit(1 if hits else 0)
