---
name: source-fidelity-gates
description: Guarantee that AI-written narration, summaries, scripts or adaptations stay faithful to a source text, using string comparison rather than model opinion. Use when turning an article/blog post/document into a video script, summary or social post; when you must prove quotes are verbatim, numbers exist in the source, every sentence maps to a source paragraph, new "framing" content is bounded, and dropped paragraphs are declared. Also for a style linter (banned phrasings) with quote exemptions.
---

# source-fidelity-gates

Every sentence of the adaptation is tied to a source paragraph, or is declared `framing` (connective tissue: transitions,
a question, a call to action). Then plain code checks it. A model may be used as a **block-only** extra
(it lists unsupported sentences; a non-empty list blocks; an empty list proves nothing).

| ID | Check | Rule |
|---|---|---|
| P1 | paragraphs are the source's | every `paragraphs{}` text occurs literally in the source (otherwise P4 and P10 would compare the adaptation with itself) |
| P2 | quotes verbatim | each non-empty `quotes[]` string occurs literally in the source |
| P3 | no additions | `addition` list is empty |
| P4 | sentence mapping | non-framing sentence has `ref` (paragraph id) and is (verbatim in it) or (paraphrase mode: letter-pair overlap >= 0.50 AND at least 60 % of its longer ASCII words occur in the paragraph) |
| P5 | bounded framing | framing chars <= 20 % of total and <= 8 framing sentences |
| P6 | numbers | digits in non-framing sentences appear in the source; framing contains no digits |
| P7 | core kept | per-document `core_keys` still occur in the narration (update per document!) |
| P10 | dropped | paragraphs you did not use == the paragraphs you declared dropped |

```bash
python3 scripts/check_fidelity.py scenario.json source.txt     # exit 0 all pass | 1 violation | 2 bad input
python3 scripts/style_lint.py text.txt --ban "will be done" --ban "is being"   # banned phrases, quotes exempt
bash tests/run.sh
```

`scenario.json`:
```json
{ "fidelity": "verbatim|paraphrase", "quotes": ["..."], "addition": [], "core_keys": ["..."], "dropped": ["p3"],
  "paragraphs": {"p1": "text...", "p2": "text..."},
  "sentences": [ {"text": "...", "ref": "p1"}, {"text": "Let's start.", "framing": true} ] }
```

## Lessons

- A hard-coded keyword list per document is a bug waiting to fire on the second document. Make `core_keys` per document.
- Bigram overlap works for Korean/Japanese/Chinese and for English (it strips non-letters); tune 0.50 on your own examples.
- Style linters: exempt text inside quotation marks, or you ban the source's own words. Put a forgery test on it.
- Narrow banned-phrase lists down to **intent** (a ban on "subscribe" would flag "video subscription" as an expense;
  ban the *request*), then add a test that catches the request and passes the expense.
