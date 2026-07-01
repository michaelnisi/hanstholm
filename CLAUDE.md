# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hanstholm is a watchOS 10 app (with a WidgetKit complication) that fetches live surf and wind conditions from the weather station at Hanstholm Harbour, Denmark (`www.hyde.dk`). The data source is a Danish-language HTML page, so parsing involves stripping HTML and mapping Danish labels and direction abbreviations to typed domain values.

## Repository Structure

```
Core/               # Swift Package — shared logic, no UI
Hanstholm Watch App/  # watchOS target
HanstholmWidget/    # WidgetKit extension target
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

`HydeTests.testFetch` hits the live network; `ParserTests` uses a hardcoded HTML fixture and is safe to run offline. Note: `ParserTests` depends on `NSAttributedString` HTML parsing and may be sensitive to OS version differences.

Build and run the watch app and widget from Xcode — there is no command-line target for the app itself.

## Architecture

### Core Package Modules (dependency order)

- **Hyde** — fetches the HTML page, strips it with `NSAttributedString`, and extracts values by finding Danish label substrings. Produces `Hyde` (the raw DTO). Also owns the `Fetcher` actor which manages both a foreground `URLSession` and a background `URLSessionConfiguration` for widget refresh. `DownloadDelegate` is `nonisolated` throughout because URLSession calls its delegate from a background thread.
- **DomainTypes** — `SurfEntry` (the clean model, also conforms to `TimelineEntry` for WidgetKit), `Direction` (16-point cardinal with Danish→English mapping and rotation degrees), and `Double` formatting extensions. `SurfEntry+Hyde.swift` is the DTO→model conversion layer; it fails loudly via `logger.error` when fields are missing.
- **Cache** — `actor Cache` backed by App Group `UserDefaults` (`group.ink.codes.Hanstholm`), shared between the app and widget extension. Stores `Hyde` values keyed by place.
- **MockData** — Canned `Hyde` and `SurfEntry` values used in SwiftUI previews and `HydeTests`.

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

`SurfProvider` is an `ObservableObject` wired into the view hierarchy via `environmentObject`. It uses a `Dependencies` struct for injection (swap `live` for `mock` in previews). The live provider caches for 5 minutes before re-fetching; on fetch it also calls `WidgetCenter.shared.reloadAllTimelines()`.

`ContentView` listens to `scenePhase` and fetches on `.active`, cancelling the task on `.background`/`.inactive`.

`SurfSpot` is a vertical `TabView` with two pages: `WindView` and `WaveView`.

### Widget Extension

`SurfEntryProvider` implements `TimelineProvider`. `getTimeline` schedules a background download (earliest begin: 15 minutes out), then resolves data with this priority: cached (<15 min old) → background download result → foreground fetch. The widget registers for `onBackgroundURLSessionEvents` matching `"www.hyde.dk"` to handle the background session wakeup.

## Concurrency Model

### Isolation strategy

- **Core package**: No default isolation. Types like `Hyde`, `SurfEntry`, and `Direction` are explicitly `Sendable` because they cross actor boundaries (e.g. the `Cache` actor decodes `Hyde` on its own executor, then the result is consumed on `@MainActor`). Do not add `defaultIsolation(MainActor.self)` to Core targets — it causes the `Cache` actor to conflict with `@MainActor`-isolated `Codable` conformances.
- **Watch App and Widget Xcode targets**: `OTHER_SWIFT_FLAGS = "-default-isolation MainActor"` is set, so all unannotated code in those targets is `@MainActor` by default.

### Key actors

- `Fetcher` — owns the URLSession and background download state. `DownloadDelegate` is fully `nonisolated` (let property, init, and delegate method) to safely receive URLSession callbacks from background threads.
- `Cache` — persists conditions to App Group `UserDefaults`. All methods require `await` at call sites.
- `SurfProvider` — `@MainActor` via the app target's module default. `Dependencies.fetchHyde` closure does not need `@Sendable` because it is only created and called within `@MainActor` context.

### Key constants

- App Group suite name: `group.ink.codes.Hanstholm`
- Background URL session identifier: `www.hyde.dk`
- Data source URL: `https://www.hyde.dk/hanstholm/vejrstation.asp` (ISO Latin-1 encoded HTML)
- Cache TTL: 5 min (app), 15 min (widget)
