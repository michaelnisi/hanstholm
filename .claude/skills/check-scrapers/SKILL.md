---
name: check-scrapers
description: Verify that scraping plugins (Hyde and any future ones) still parse their live sources, and when one is broken, file an issue and open a PR that repairs the parser. Use when asked to check scrapers, check Hyde, test whether parsing still works, or when a parser seems broken.
---

# check-scrapers

Probes every registered plugin against its live source. Healthy: report and stop. Broken: reuse or file an issue, then repair the parser on a `GH-N-…` branch and open a PR. Never merge.

This skill is a deliberate exception to the plan-mode rule in CLAUDE.md: it may file the issue, branch, fix and open the PR without prior sign-off. The issue and PR are the transparency. Everything else in CLAUDE.md still applies: no comments, assignment/call grouping, branch and commit naming, pulling the base branch in before review, and a human merges.

## 1. Probe

Run from the repository root, with a directory in the scratchpad for the saved pages:

```bash
swift run --package-path .claude/skills/check-scrapers/probe probe <scratchpad>/live
```

The probe fetches each place of each plugin listed in `probe/Sources/probe/main.swift`, saves the raw bytes as `<place key>.html`, runs the plugin's own `decodeDeferred`, and prints one JSON line per place:

| status | meaning |
| --- | --- |
| `healthy` | fetched and decoded into a `SurfEntry` |
| `broken` | the source answered but the plugin cannot use it: HTTP 4xx (page moved or removed) or a decoding failure |
| `unavailable` | the page is understood, but the provider intentionally left a part (wave or wind) out: every numeric reading of that part holds a placeholder without digits; `detail` names the part |
| `unreachable` | transport error or HTTP 5xx; the site is down, which is not a parser bug |

Exit code 0: no place is broken. 1: at least one is broken. 2: bad arguments.

To replay saved pages instead of fetching (drills, reproducing a failure): add `--replay <directory>` containing `<place key>.html` files.

New plugin: add one line to the `plugins` array in `main.swift`, and the matching library product dependency in the probe's `Package.swift` if it is not already linked.

## 2. Decide

- All `healthy`: report per place and stop. No issue, no PR.
- Only `healthy`, `unavailable` and `unreachable`: report each and stop. An `unavailable` part is the provider's choice, not a parser bug, so there is no issue and no PR. A part that is partly filled, a renamed label, or numbers that no longer parse is `broken`, never `unavailable`.
- Any `broken`: continue.

## 3. Issue

Search first, never duplicate:

```bash
gh issue list --state open --search "<plugin name> parser OR scraper OR 404 in:title,body"
```

If an open issue already covers that plugin and place, comment on it with the new evidence and use its number. Otherwise file one with the place, the probe's `detail`, the failing URL, the date, and what the live page looks like now.

One issue and one PR per plugin when the cause is shared; separate ones when the causes differ.

## 4. Repair

1. Check the working tree is clean, fetch, branch from the up-to-date `main`: `GH-<N>-fix-<plugin>-parser`.
2. Work out what changed in the saved live page (new URL, renamed labels, restructured sections) and update the plugin's parsing and, if the source moved, its URLs. The plugin owns its vocabulary; do not touch `DomainTypes`.
3. Replace or add a **trimmed fixture** for each repaired place next to the plugin's existing fixtures (Hyde: inline `let …HTML = """` literals in `Core/Tests/HydeTests/ParserTests.swift`). Keep only what the parser reads. Drop scripts, navigation, tracking and anything that differs between fetches.
4. Update or add tests so the new behavior is pinned; the test name carries the why. No comments.
5. Run `cd Core && swift test`, then `xcrun swift-format format --in-place --configuration ../.swift-format --recursive Sources Tests` and confirm `xcrun swift-format lint --configuration ../.swift-format --strict --recursive Sources Tests` is clean.
6. Re-run the probe; every repaired place must now report `healthy`.
7. Commit with the `GH-<N> …` prefix, merge `main` into the branch, push, and open a PR titled like the commit whose body opens with `Closes #<N>` and describes the as-built change, including what the live page looked like before and after.

## Stop conditions

- Never merge, never push to `main`, never close an issue by hand.
- If, after a reasonable attempt, the fix is not clear, leave the issue open with your findings and do not open a speculative PR. Say so in the report.
- Report to the user: per-place status, the issue link, and the PR link if there is one.
