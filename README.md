# llm-adaptation-fidelity-check

**Check that an adaptation of a source text stays faithful: verbatim quotes, no invented sentences or numbers, bounded framing, declared omissions.**

[![test](https://github.com/Kein-chronicle/llm-adaptation-fidelity-check/actions/workflows/test.yml/badge.svg)](https://github.com/Kein-chronicle/llm-adaptation-fidelity-check/actions/workflows/test.yml) ![license](https://img.shields.io/badge/license-MIT-blue.svg) ![dependencies](https://img.shields.io/badge/dependencies-none-brightgreen.svg)

## Why

When an LLM rewrites a source, the failures are specific: a quote gets reworded, a number appears from nowhere, filler pads the length, a paragraph is dropped silently. These are checked with string and number comparison, not another model.

## Install

**As a Claude Code skill** (Claude uses it when the task matches the skill description):

```sh
git clone https://github.com/Kein-chronicle/llm-adaptation-fidelity-check.git ~/.claude/skills/source-fidelity-gates
```

For a single project, clone into `<project>/.claude/skills/source-fidelity-gates` instead, then start a new Claude Code session.

**As plain scripts:**

```sh
git clone https://github.com/Kein-chronicle/llm-adaptation-fidelity-check.git
cd llm-adaptation-fidelity-check
```

**Requires:** Python 3.10+.

## Quick start

Check a good and two bad adaptations:

```console
$ bash examples/demo.sh
# A faithful adaptation of a source text
$ python3 scripts/check_fidelity.py tests/fixtures/good.json tests/fixtures/source.txt
[PASS] P1 paragraphs are verbatim from the source
[PASS] P2 quotes verbatim
[PASS] P3 no additions
[PASS] P4 every sentence maps to a paragraph
[PASS] P5 framing bounded
[PASS] P6 numbers exist in source
[PASS] P7 core kept
[PASS] P10 dropped == declared
[exit 0]

# A quote the adaptation altered, and a number it invented
$ python3 scripts/check_fidelity.py tests/fixtures/bad_quote.json tests/fixtures/source.txt
[PASS] P1 paragraphs are verbatim from the source
[FAIL] P2 quotes verbatim
[PASS] P3 no additions
[PASS] P4 every sentence maps to a paragraph
[PASS] P5 framing bounded
[PASS] P6 numbers exist in source
[PASS] P7 core kept
[PASS] P10 dropped == declared
[exit 1]

$ python3 scripts/check_fidelity.py tests/fixtures/bad_number.json tests/fixtures/source.txt
[PASS] P1 paragraphs are verbatim from the source
[PASS] P2 quotes verbatim
[PASS] P3 no additions
[FAIL] P4 every sentence maps to a paragraph
[PASS] P5 framing bounded
[FAIL] P6 numbers exist in source
[PASS] P7 core kept
[PASS] P10 dropped == declared
[exit 1]

# Banned phrases are caught outside quotes but allowed inside them
$ python3 scripts/style_lint.py .demo-tmp/bad.txt --ban is being done
banned phrase 'is being done' at offset 3
[exit 1]

$ python3 scripts/style_lint.py .demo-tmp/ok.txt --ban is being done
[exit 0]
```

The output above is real: it is produced by the files in `examples/`.

## Use it on your own files

```sh
python3 scripts/check_fidelity.py adaptation.json source.txt
python3 scripts/style_lint.py adaptation.txt --ban "is being done"
```

Sample inputs for every file format are in `examples/` and `tests/`; the details are in [SKILL.md](SKILL.md).

## What it checks

- `check_fidelity.py adaptation.json source.txt` runs P1 paragraphs are verbatim from the source, P2 quotes verbatim, P3 no additions, P4 every sentence maps to a source paragraph, P5 framing bounded, P6 numbers exist in source, P7 core kept (an empty `core_keys` list fails), P10 dropped paragraphs are declared. Numbers are compared as digits; spelled-out numbers are not checked.
- `style_lint.py file --ban phrase` finds banned phrases outside quotation marks (inside quotes they are allowed), case-insensitively and across line breaks; offsets index the original file; an empty ruleset is refused.

## Limits

- Deterministic matching: it will not understand meaning. Paraphrase mode compares words and letter pairs, so a cleverly worded invented claim can still pass; it catches careless additions, not adversarial ones.

## Related projects

These solve neighbouring problems; use them when they fit better.

- **Ragas and other RAG faithfulness evaluators**: use an LLM to judge faithfulness; these gates are deterministic

## More from the same collection

Small, tested tools that grew out of running AI agents and game/app pipelines for months:

- [**canvas-render-pixel-gate**](https://github.com/Kein-chronicle/canvas-render-pixel-gate): Detect grey-box screenshots: measure unique colors and flat-fill share of a rendered game canvas, and refuse to pass what it could not measure.
- [**web-game-asset-reality-check**](https://github.com/Kein-chronicle/web-game-asset-reality-check): Catch web-game bugs the type checker can't: fonts that are declared but not shipped, runtime CDN dependencies, and page errors from headless Chromium.
- [**ffmpeg-video-qa-gates**](https://github.com/Kein-chronicle/ffmpeg-video-qa-gates): Machine QA for short videos with ffmpeg: frozen frames, dead air, loudness, true peak, size, a busy opening, and readable subtitle timing.

## Development

```sh
bash tests/run.sh
```

The tests include inputs that are supposed to be rejected, so a green run also shows the checks can fail. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

If this saved you a debugging session, a star helps other people find it. Bug reports and failing test cases are even better.

<sub>Keywords: content, fact-checking, llm-evaluation, adaptation, editorial, quality-gates, claude-skills, agent-skills</sub>
