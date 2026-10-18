#!/usr/bin/env bash
set -u; here="$(cd "$(dirname "$0")" && pwd)"; s="$here/../scripts"; f="$here/fixtures"; bad=0
t() { name="$1"; want="$2"; shift 2; out="$("$@" 2>&1)"; got=$?; [ "$got" = "$want" ] && echo "ok   $name" || { echo "FAIL $name (want $want got $got)"; echo "$out"|sed 's/^/     /'; bad=1; }; }
tr() { name="$1"; pat="$2"; shift 2; out="$("$@" 2>&1)"; echo "$out" | grep -q "FAIL.*$pat" && echo "ok   $name (failed on: $pat)" || { echo "FAIL $name: expected FAIL on '$pat'"; echo "$out"|sed 's/^/     /'; bad=1; }; }
t  "faithful adaptation passes" 0 python3 "$s/check_fidelity.py" "$f/good.json" "$f/source.txt"
tr "altered quote caught"       "P2" python3 "$s/check_fidelity.py" "$f/bad_quote.json" "$f/source.txt"
tr "invented sentence caught"   "P4" python3 "$s/check_fidelity.py" "$f/bad_sentence.json" "$f/source.txt"
tr "invented number caught"     "P6" python3 "$s/check_fidelity.py" "$f/bad_number.json" "$f/source.txt"
tr "padding with framing caught" "P5" python3 "$s/check_fidelity.py" "$f/bad_framing.json" "$f/source.txt"
tr "undeclared dropped paragraph" "P10" python3 "$s/check_fidelity.py" "$f/bad_dropped.json" "$f/source.txt"
tr "lost core idea caught"      "P7" python3 "$s/check_fidelity.py" "$f/bad_core.json" "$f/source.txt"
tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
printf 'We will do it. The author says "it is being done" here.\n' > "$tmpd/sl_ok.txt"
printf 'It is being done by us.\n' > "$tmpd/sl_bad.txt"
t  "banned phrase inside quotes is exempt" 0 python3 "$s/style_lint.py" $tmpd/sl_ok.txt --ban "is being done"
t  "banned phrase outside quotes is caught" 1 python3 "$s/style_lint.py" $tmpd/sl_bad.txt --ban "is being done"
t  "empty ruleset refused" 2 python3 "$s/style_lint.py" $tmpd/sl_ok.txt
# --- review findings: each of these used to pass
mk() { python3 - "$tmpd" "$1" <<'PY'
import json, sys
d, kind = sys.argv[1], sys.argv[2]; g = json.load(open(__import__("os").environ["F"] + "/good.json"))
if kind == "invented":      # paragraph texts invented, sentences match them: the scenario compares itself with itself
    g["paragraphs"] = {"p1": "Bicycles cause cancer. The author admits fraud.", "p2": "Everything is a lie."}
    g["sentences"] = [{"text": "Bicycles cause cancer.", "ref": "p1"}, {"text": "The author admits fraud.", "ref": "p1"}, {"text": "Everything is a lie.", "ref": "p2"}]
    g["quotes"] = []; g["dropped"] = []
if kind == "paraphrase":    # an invented clause that rides on shared letter pairs
    g["fidelity"] = "paraphrase"; g["sentences"][2] = {"text": "After that, the bicycle is certainly the natural enemy of the author and every rider is lying.", "ref": "p2"}
if kind == "number":        # a '3' that only exists inside '13'
    open(d + "/num_src.txt", "w").write("The route is 13 km long.\n")
    g = {"fidelity": "verbatim", "quotes": [], "addition": [], "core_keys": ["route"], "dropped": [], "paragraphs": {"p1": "The route is 13 km long."},
         "sentences": [{"text": "The route is 3 km long.", "ref": "p1"}]}
if kind == "emptyquote":    g["quotes"] = [""]
if kind == "nocore":        g["core_keys"] = []
if kind == "malformed":     g = {"sentences": [{"ref": "p1"}]}
json.dump(g, open(d + "/" + kind + ".json", "w"))
PY
}
export F="$f"
for k in invented paraphrase number emptyquote nocore malformed; do mk $k; done
tr "invented paragraphs are not the source's text" "P1" python3 "$s/check_fidelity.py" "$tmpd/invented.json" "$f/source.txt"
tr "invented clause in paraphrase mode is caught" "P4" python3 "$s/check_fidelity.py" "$tmpd/paraphrase.json" "$f/source.txt"
tr "number match respects digit boundaries"       "P6" python3 "$s/check_fidelity.py" "$tmpd/number.json" "$tmpd/num_src.txt"
tr "an empty quote string is not a verbatim quote" "P2" python3 "$s/check_fidelity.py" "$tmpd/emptyquote.json" "$f/source.txt"
tr "no core_keys means nothing was checked"       "P7" python3 "$s/check_fidelity.py" "$tmpd/nocore.json" "$f/source.txt"
t  "a malformed scenario is exit 2, not a traceback" 2 python3 "$s/check_fidelity.py" "$tmpd/malformed.json" "$f/source.txt"
printf 'It Is Being\nDone by us.\n' > "$tmpd/sl_case.txt"
t  "banned phrase is case-insensitive and survives a line break" 1 python3 "$s/style_lint.py" "$tmpd/sl_case.txt" --ban "is being done"
printf 'Pipe 5" wide. It is being done. Pipe 6" long.\n' > "$tmpd/sl_inch.txt"
t  "inch marks do not open a quote that hides the rest" 1 python3 "$s/style_lint.py" "$tmpd/sl_inch.txt" --ban "is being done"
out="$(python3 "$s/style_lint.py" "$tmpd/sl_bad.txt" --ban "is being done" 2>&1)"; echo "$out" | grep -q "offset 3" && echo "ok   offsets index the original text" || { echo "FAIL offset: $out"; bad=1; }
# --- second review round
printf '자전거는 느리지만 안전하다. 저자는 매일 아침 공원에서 타고 다닌다.\n' > "$tmpd/ko.txt"
python3 - "$tmpd" <<'PY'
import json, sys
d = sys.argv[1]; base = {"fidelity": "paraphrase", "quotes": [], "addition": [], "core_keys": ["자전거"], "dropped": [], "paragraphs": {"p1": "자전거는 느리지만 안전하다. 저자는 매일 아침 공원에서 타고 다닌다."}}
json.dump(dict(base, sentences=[{"text": "자전거는 안전하지만 느리다. 저자는 매일 저녁 공원에서 걷지 않는다.", "ref": "p1"}]), open(d + "/ko_bad.json", "w"), ensure_ascii=False)
json.dump(dict(base, sentences=[{"text": "저자는 매일 아침 공원에서 타고 다닌다.", "ref": "p1"}, {"text": "자전거는 느리지만 안전하다.", "ref": "p1"}]), open(d + "/ko_ok.json", "w"), ensure_ascii=False)
json.dump([1], open(d + "/list.json", "w"))
json.dump(dict(base, fidelity="verbatim", sentences=[{"text": "", "ref": "p1"}]), open(d + "/empty.json", "w"), ensure_ascii=False)
PY
tr "an invented Korean clause cannot ride on shared letter pairs" "P4" python3 "$s/check_fidelity.py" "$tmpd/ko_bad.json" "$tmpd/ko.txt"
t  "a faithful Korean paraphrase passes" 0 python3 "$s/check_fidelity.py" "$tmpd/ko_ok.json" "$tmpd/ko.txt"
t  "a scenario that is a JSON list is exit 2" 2 python3 "$s/check_fidelity.py" "$tmpd/list.json" "$tmpd/ko.txt"
tr "an empty sentence maps to nothing" "P4" python3 "$s/check_fidelity.py" "$tmpd/empty.json" "$tmpd/ko.txt"
exit $bad
