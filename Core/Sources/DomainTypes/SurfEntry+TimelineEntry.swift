#if canImport(WidgetKit)
import WidgetKit

extension SurfEntry: TimelineEntry {
    public var relevance: TimelineEntryRelevance? {
        switch status {
        case .ok:
            TimelineEntryRelevance(score: 50, duration: Self.cacheTTL)
        case .error, .placeholder:
            TimelineEntryRelevance(score: 0)
        }
    }
}
#endif
