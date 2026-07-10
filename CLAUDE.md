# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hanstholm is a watchOS 10 app (with a WidgetKit complication) that fetches live surf and wind conditions from the weather station at Hanstholm Harbour, Denmark (`hyde.dk`). The data source is a Danish-language HTML page; parsing involves stripping HTML with `NSAttributedString` and mapping Danish labels and direction abbreviations to typed domain values.

## Workflow for New Features

When discussing a new thing (a feature, change, or non-trivial fix), follow this sequence rather than jumping straight to code:

1. **Basic plan** — a short back-and-forth with the user to sketch the approach and confirm scope/direction.
2. **GitHub issue** — file an issue capturing that basic plan. This is a snapshot of the initial understanding, not a living document — don't go back and update it as the detailed plan or implementation evolves.
3. **Detailed plan** — work out the concrete implementation plan in plan mode. The plan stays in the session; the issue from step 2 doesn't need to be updated to reflect it.
4. **Branch** — create a feature branch for the work.
5. **PR** — implement on the branch and open a pull request that closes the issue. The PR description is where the detailed, as-built understanding gets written down.

The reason for the strict ordering: work should be abortable at any stage and still leave one coherent artifact behind. Before the issue exists, aborting just drops the chat — that's fine, nothing was committed to yet. Once the issue exists, it's the recoverable checkpoint: the initial understanding is enough to pick the thread back up later, even if the detailed plan or a branch never materialized, which is exactly why the issue doesn't need to be kept in sync with later changes of mind. A branch with no PR isn't a coherent artifact, so don't leave one open without a PR.

Skip this sequence for small, obviously-scoped fixes (typos, one-line bugs) — it's for things substantial enough to warrant discussion first.

Every distinct piece of work gets its own issue, branch, and PR — never stack unrelated changes onto one branch/PR. If the conversation seems to move on to a new topic partway through, ask whether a new issue should be opened for it rather than folding it into the current one.

## Repository Structure

```
Core/                 # Swift Package — shared logic, no UI
Hanstholm Watch App/  # watchOS target
HanstholmWidget/      # WidgetKit extension target
```

## Building and Testing

The Core package has its own test suite:

```bash
cd Core
swift build
swift test                                 # run all tests
swift test --filter ParserTests            # run a single test class
swift test --filter ParserTests/testWave   # run a single test
```

`HydeTests.testFetch` hits the live network. `ParserTests` uses a hardcoded HTML fixture and is safe to run offline, but depends on `NSAttributedString` HTML parsing so may be sensitive to OS version differences.

Build and run the watch app and widget from Xcode — there is no command-line target for the app.

## Architecture

### Core Package (dependency order)

- **Hyde** — fetches `https://hyde.dk/default_hanstholm.asp` (UTF-8 HTML), strips it via `NSAttributedString`, and extracts values by finding Danish label substrings within named sections (to disambiguate repeated labels like "aktuelt" and "middel"). Produces `Hyde` (raw DTO). `Fetcher` actor owns both a foreground `URLSession` and a background `URLSessionConfiguration` for widget refresh. `DownloadDelegate` is fully `nonisolated` to safely receive URLSession callbacks from background threads.
- **DomainTypes** — `SurfEntry` (clean model, also conforms to `TimelineEntry`), `Direction` (16-point cardinal with Danish→English mapping and rotation degrees), and `Double` formatting extensions. `SurfEntry+Hyde.swift` converts DTO→model; it returns `nil` and logs via `logger.error` when any field is missing.
- **Cache** — `actor Cache` backed by App Group `UserDefaults` (`group.ink.codes.Hanstholm`), shared between app and widget. Methods are `throws` (not `async`) — actor isolation handles concurrency. Stores `Hyde` values keyed by place.
- **MockData** — Canned `Hyde` and `SurfEntry` values for SwiftUI previews and tests.

### Data Flow

```
hyde.dk HTML → Fetcher → Parser → Hyde (DTO)
                                      ↓
                              SurfEntry+Hyde (conversion)
                                      ↓
                              SurfEntry (domain model)
                              → Cache (App Group UserDefaults)
                              → UI / Widget timeline
```

### Watch App

`SurfProvider` is `@Observable` (Observation framework) and is injected into the view hierarchy via `.environment(SurfProvider.live)`. It uses a `Dependencies` struct for injection (swap `.live` for `.mock` in previews). The live provider caches for 5 minutes before re-fetching; on a live fetch it calls `WidgetCenter.shared.reloadAllTimelines()`.

`ContentView` observes `scenePhase` and starts a fetch task on `.active`, cancelling it on `.background`/`.inactive`.

`SurfSpot` is a vertical `TabView` with two pages: `WindView` and `WaveView`.

### Widget Extension

`SurfEntryProvider` implements `TimelineProvider`. `getTimeline` schedules a background download (earliest begin: 15 minutes), then resolves data with this priority: cached (<15 min old) → background download result → foreground fetch. The timeline policy is `.after(15 min)` as a guaranteed fallback; the background session also drives refresh. The widget registers for `onBackgroundURLSessionEvents` matching `"hyde.dk"`.

## Concurrency Model

- **Core package**: No default isolation. `Hyde`, `SurfEntry`, and `Direction` are explicitly `Sendable`. Do not add `defaultIsolation(MainActor.self)` to Core targets — it causes the `Cache` actor to conflict with `@MainActor`-isolated `Codable` conformances.
- **Watch App and Widget Xcode targets**: `OTHER_SWIFT_FLAGS = "-default-isolation MainActor"` is set, so all unannotated code in those targets is `@MainActor` by default.
- `DownloadDelegate` is `nonisolated` throughout (stored property, `init`, and delegate method) to safely receive URLSession callbacks from background threads.

## Key Constants

| Constant | Value |
|----------|-------|
| App Group suite | `group.ink.codes.Hanstholm` |
| Background URL session ID | `hyde.dk` |
| Data source URL | `https://hyde.dk/default_hanstholm.asp` |
| Cache TTL (app) | 5 min |
| Cache TTL (widget) | 15 min |

## Quirks

- `Direction.degrees` encodes rotation for a compass arrow that points toward the origin: South = 0°, values increase clockwise. This is intentional — the arrow rotates to show where wind/current is coming *from*.
- Danish direction abbreviations use `Ø` (east) and `V` (west), not `E`/`W`; the full mapping is in `Direction.danishToCardinal`.
- The Parser locates values by finding the Danish label line and returning the *next* line. Repeated labels ("aktuelt", "middel") are disambiguated with `substring(after:within:)`, which scopes the search to a named section heading — section order in the HTML is the implicit contract with the data source.
