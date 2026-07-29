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
Hanstholm/            # iOS companion app target (hosts the Watch app and the iOS widget extension)
Hanstholm Watch App/  # watchOS target
HanstholmWidget/      # WidgetKit extension source, shared by two Xcode targets:
                       #   HanstholmWidgetExtension    (watchOS, embedded in the Watch App)
                       #   HanstholmWidgetIOSExtension (iOS, embedded in the "Hanstholm" container app)
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

Every test runs offline: fetching lives behind `SurfConditionsPlugin`, which the coordinator tests stub, and `ConditionsTests` passes `deferredDownloads: nil` so no background `URLSession` is created in the test process. `ParserTests` uses a hardcoded HTML fixture but depends on `NSAttributedString` HTML parsing, so it may be sensitive to OS version differences.

Build and run the watch app and widget from Xcode — there is no command-line target for the app.

## Architecture

### Core Package (dependency order)

- **DomainTypes** — `SurfEntry` (clean model, also conforms to `TimelineEntry`), `Direction` (16-point cardinal with Danish→English mapping and rotation degrees), and `Double` formatting extensions. Depends on nothing: the domain layer must not know about any particular source.
- **Hyde** — a pure, synchronous parser with no dependencies. Strips HTML via `NSAttributedString` and extracts values by finding Danish label substrings within named sections (to disambiguate repeated labels like "aktuelt" and "middel"). Produces `Hyde` (raw DTO). Does no networking at all; `Hyde.Place.url` just names where the data lives.
- **SurfConditions** — `SurfConditionsPlugin` (a source of conditions) and `DeferredDownloadable` (opt-in: "my data is one plain download whose bytes decode standalone").
- **Cache** — `actor Cache` backed by App Group `UserDefaults` (`group.ink.codes.Hanstholm`), shared between app and widget. Methods are `throws` (not `async`) — actor isolation handles concurrency. Stores `SurfEntry` values keyed by place.
- **HydePlugin** — adapts `Hyde` to the plugin protocol, and owns `SurfEntry+Hyde.swift` (DTO→model conversion, returning `nil` and logging when a field is missing). Lives here rather than in `DomainTypes` so the dependency arrow points source→domain.
- **Conditions** — `ConditionsCoordinator` plus the background `URLSession` machinery. Everything that isn't HTTP or parsing.
- **MockData** — Canned `Hyde` and `SurfEntry` values for SwiftUI previews and tests.

**Plugin responsibility** is exactly two things: HTTP (with a session handed to it) and parsing. Caching, freshness policy, place selection, background download scheduling and delivery, and widget timeline reloads all belong to the coordinator.

### Data Flow

```
ConditionsCoordinator
  ├─ reads Cache first, subject to a FreshnessPolicy
  ├─ on miss: plugin.conditions(for:using:)  ── HTTP + parsing ──→ SurfEntry
  └─ writes through to Cache, then reloads widget timelines
                                      ↓
                              Cache (App Group UserDefaults)
                              → UI / Widget timeline

Deferred path (widget extensions only):
  scheduleDeferredRefresh → background URLSession → DeferredDownloader
                                      ↓
                    plugin.decodeDeferred → Cache (same write-through)
```

### Container App

`Hanstholm/` uses `fileSystemSynchronizedGroups`, like the Watch App and widget targets — files dropped in the folder are picked up automatically, no manual pbxproj membership needed. The target is a real `application` product type (not the watch-only-companion stub it started as), declaring `INFOPLIST_KEY_WKCompanionAppBundleIdentifier` to pair with the Watch app.

`ContentView.swift` is a minimal, read-only screen: it reads `Cache().conditions(matching:)` on `.task` and whenever `scenePhase` becomes `.active`, and renders the resulting `SurfEntry` (or a `ContentUnavailableView` prompt if nothing's cached yet). It never fetches — it only shows what some other *iOS-side* process has already written to the shared App Group `Cache`. Note the Watch app doesn't count: App Groups only share storage between processes on the same device, so the Watch's cache and the iPhone's cache are entirely separate — this screen only has data once the iOS widget extension (or some other iOS-side fetcher) has populated the cache. `MockData` is preview-only here, never a runtime fallback, so the screen can't show fabricated data as if it were live.

### Watch App

`SurfProvider` is `@Observable` (Observation framework) and is injected into the view hierarchy via `.environment(SurfProvider.live)`. It uses a `Dependencies` struct for injection (swap `.live` for `.mock` in previews). `.live` is a thin wrapper over `ConditionsCoordinator.watchApp`, asking for `.cached(maxAge: 5 * 60)`; the coordinator owns the caching and the timeline reload.

The watch app's coordinator sets `deferredDownloads: nil` — it refreshes through `WKApplication` background tasks, not a background `URLSession`, so it creates no download session. The widget extension owns that path; the two meet in the shared `Cache`, never in memory.

`ContentView` observes `scenePhase` and starts a fetch task on `.active`, cancelling it on `.background`/`.inactive`.

`SurfSpot` is a vertical `TabView` with two pages: `WindView` and `WaveView`.

### Widget Extension

`SurfEntryProvider` implements `TimelineProvider`. `getTimeline` schedules a deferred download (earliest begin: 15 minutes), then resolves data in **two** tiers: cached (<15 min old) → foreground fetch. There is no third "background result" tier, because a finished download is written straight through to the `Cache` by `DeferredDownloader` — by the time anything asks, it *is* the cache. That also means the result survives the extension process being relaunched, which the old in-memory handoff did not.

The timeline policy is `.after(15 min)` as a guaranteed fallback; the background session also drives refresh. The widget registers for `onBackgroundURLSessionEvents` matching `DeferredDownloadConfiguration.defaultSessionIdentifier()` — the same helper that builds the session identifier, so the two cannot drift apart.

A background session created inside an app extension **must** set `sharedContainerIdentifier`, or downloads silently fail to start.

The `HanstholmWidget/` source compiles unchanged into two separate Xcode targets — `HanstholmWidgetExtension` (watchOS complications) and `HanstholmWidgetIOSExtension` (iOS Lock Screen widgets) — via a shared `fileSystemSynchronizedGroups` membership, plus a shared `Info.plist` and `HanstholmWidgetExtension.entitlements`. Only the four accessory widget families (`.accessoryCorner/.accessoryCircular/.accessoryInline/.accessoryRectangular`) are wired up; there's no Home Screen (`.systemSmall`/`.systemMedium`) layout yet. Each extension is a separate process/bundle ID, and the session identifier is bundle-scoped, so their background sessions stay apart.

## Concurrency Model

- **Core package**: No default isolation. `Hyde`, `SurfEntry`, and `Direction` are explicitly `Sendable`. Do not add `defaultIsolation(MainActor.self)` to Core targets — it causes the `Cache` actor to conflict with `@MainActor`-isolated `Codable` conformances.
- **Watch App and Widget Xcode targets**: `OTHER_SWIFT_FLAGS = "-default-isolation MainActor"` is set, so all unannotated code in those targets is `@MainActor` by default.
- `DeferredDownloader` is a lock-guarded class, not an actor, because the WidgetKit background-events handler and the `URLSession` delegate queue both reach it from `nonisolated` contexts and need answers synchronously. `NSLock` rather than `Synchronization.Mutex` — the package deploys to watchOS 10 and `Mutex` needs 11.
- `ConditionsCoordinator.handleBackgroundSessionEvents` is `nonisolated` for the same reason: registering the completion behind an `await` lets a download that already finished find nothing to call.

## Key Constants

| Constant | Value |
|----------|-------|
| App Group suite | `group.ink.codes.Hanstholm` |
| Background URL session ID | `<bundle id>.conditions` (was `hyde.dk`) |
| Data source URL | `https://hyde.dk/default_hanstholm.asp` |
| Cache TTL (app) | 5 min |
| Cache TTL (widget) | 15 min |

## Quirks

- `Direction.degrees` encodes rotation for a compass arrow that points toward the origin: South = 0°, values increase clockwise. This is intentional — the arrow rotates to show where wind/current is coming *from*.
- Danish direction abbreviations use `Ø` (east) and `V` (west), not `E`/`W`; the full mapping is in `Direction.danishToCardinal`.
- The Parser locates values by finding the Danish label line and returning the *next* line. Repeated labels ("aktuelt", "middel") are disambiguated with `substring(after:within:)`, which scopes the search to a named section heading — section order in the HTML is the implicit contract with the data source.
