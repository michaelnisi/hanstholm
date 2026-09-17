# Patrol 🌊

A glance at your wrist tells you whether it's worth driving to the coast.

Wave height, period, and wind — live from the harbour weather stations along Denmark's North Sea coast 🇩🇰: Hanstholm, Hvide Sande, and Thorsminde. Pick a spot on your watch and it shows on your watch face as a complication. A companion app on your iPhone mirrors the same conditions, with its own Lock Screen widget.

Built for watchOS 26 ⌚️ and iOS 📱

## Architecture

```mermaid
flowchart TD
    A["hyde.dk (Danish HTML)"] --> B["Hyde<br/>parses Danish labels → SurfEntry"]
    B --> C["ConditionsCoordinator<br/>fetch, freshness policy, caching"]
    C --> D["Cache<br/>shared App Group storage"]
    D --> E1["Watch App<br/>(live UI)"]
    D --> E2["Watch complication<br/>(widget extension)"]
    D --> E3["iPhone app<br/>(read-only mirror)"]
    D --> E4["Lock Screen widget<br/>(iPhone)"]
```
