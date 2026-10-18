#!/usr/bin/env python3
"""source-fidelity-gates: string-comparison checks of an adaptation against its source. exit 0 all pass | 1 a check failed | 2 bad input
Numbers are compared as written (digits only; spelled-out numbers are not checked). Paraphrase mode compares words and letter pairs; it will not understand meaning."""
import json, re, sys

COV_MIN, WORD_COV_MIN, FRAMING_RATIO_MAX, FRAMING_SENT_MAX = 0.50, 0.60, 0.20, 8

def strip(s): return re.sub(r"\s+", " ", re.sub(r"\*\*", "", s)).strip()
def clean(s): return re.sub(r"[^0-9A-Za-zÀ-ɏ぀-ヿ㐀-鿿가-힣]", "", s.replace("**", ""))
def bigrams(s):
    c = clean(s); return {c[i:i+2] for i in range(len(c) - 1)}
def coverage(text, ref):
    a, b = bigrams(text), bigrams(ref)
    return len(a & b) / len(a) if a else 0.0
def words(s):
    """Content words: ASCII words of 4+ letters, plus whole words of other scripts (a Korean or Japanese sentence is compared word by word as well as letter pair by letter pair)."""
    return {w for w in re.findall(r"[A-Za-z]{4,}|[^\W\d_A-Za-z]{2,}", s.lower())}
def word_coverage(text, ref):
    """Share of the sentence's content words (see words()) that occur as the same word in the referenced paragraph. Exact words only: a faithful paraphrase that
    changes word endings may fail this check (conservative, and documented), but an invented clause cannot ride on shared letter pairs."""
    a = words(text); r = words(ref)
    return len(a & r) / len(a) if a else 1.0
def numbers(s): return set(re.findall(r"\d+(?:[.,]\d+)*", s))

def check(sc, source):
    if not isinstance(sc, dict): raise TypeError("the scenario must be a JSON object")
    body = strip(source); paras = sc["paragraphs"]; res = {}
    sents = sc["sentences"]; nonf = [s for s in sents if not s.get("framing")]; fr = [s for s in sents if s.get("framing")]
    # P1: the scenario's paragraph texts must BE the source's text; otherwise P4 and P10 would compare the adaptation with itself
    res["P1 paragraphs are verbatim from the source"] = bool(paras) and all(isinstance(t, str) and strip(t) and strip(t) in body for t in paras.values())
    res["P2 quotes verbatim"] = all(isinstance(q, str) and strip(q) and strip(q) in body for q in sc.get("quotes", []))
    res["P3 no additions"] = len(sc.get("addition", [])) == 0
    paraphrase = sc.get("fidelity") == "paraphrase"; p4 = True
    for s in nonf:
        if not strip(str(s.get("text", ""))): p4 = False; continue                  # an empty sentence maps to nothing
        ref = s.get("ref")
        if not ref or ref.split(",")[0] not in paras: p4 = False; continue
        rt = " ".join(paras.get(r, "") for r in ref.split(","))
        p4 &= (coverage(s["text"], rt) >= COV_MIN and word_coverage(s["text"], rt) >= WORD_COV_MIN) if paraphrase else (strip(s["text"]) in strip(rt))
    res["P4 every sentence maps to a paragraph"] = p4 and bool(nonf)
    total = sum(len(s["text"]) for s in sents) or 1; frc = sum(len(s["text"]) for s in fr)
    res["P5 framing bounded"] = frc / total <= FRAMING_RATIO_MAX and len(fr) <= FRAMING_SENT_MAX
    src_nums = numbers(body); nums = [n for s in nonf for n in numbers(s["text"])]
    res["P6 numbers exist in source"] = all(n in src_nums for n in nums) and not any(re.search(r"\d", s["text"]) for s in fr)
    spoken = " ".join(s["text"] for s in sents)
    core = sc.get("core_keys", [])
    res["P7 core kept"] = bool(core) and all(isinstance(k, str) and k and k in spoken for k in core)       # no core_keys = nothing checked = not a pass
    used = {r for s in nonf for r in (s.get("ref") or "").split(",")}
    res["P10 dropped == declared"] = sorted(set(paras) - used) == sorted(sc.get("dropped", []))
    return res

if __name__ == "__main__":
    if len(sys.argv) != 3: print(__doc__); sys.exit(2)
    try:
        sc = json.load(open(sys.argv[1])); src = open(sys.argv[2], encoding="utf-8").read()
    except Exception as e:
        print(f"bad input: {e}"); sys.exit(2)
    if not isinstance(sc, dict) or not sc.get("sentences"): print("bad input: the scenario must be a JSON object with a non-empty \"sentences\" list"); sys.exit(2)
    try: res = check(sc, src)
    except (KeyError, TypeError, AttributeError, ValueError) as e:
        print(f"bad input: the scenario is malformed ({type(e).__name__}: {e}). Needs paragraphs{{id: text}} and sentences[{{text, ref|framing}}]"); sys.exit(2)
    for k, v in res.items(): print(f"[{'PASS' if v else 'FAIL'}] {k}")
    sys.exit(0 if all(res.values()) else 1)
