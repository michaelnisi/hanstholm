import Conditions
import SwiftUI
import WidgetKit

@main
struct PatrolWidget: Widget {
    let kind: String = "PatrolWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SurfPlaceConfigurationIntent.self,
            provider: SurfEntryProvider()
        ) { entry in
            PatrolWidgetEntryView(entry: entry)
        }
        .onBackgroundURLSessionEvents(
            matching: DeferredDownloadConfiguration.defaultSessionIdentifier()
        ) { urlSessionEvent, completion in
            ConditionsCoordinator.shared.handleBackgroundSessionEvents {
                completion()
            }
        }
        .configurationDisplayName("Patrol")
        .description("Surf and wind conditions for your spot.")
        #if os(watchOS)
        .supportedFamilies([
            .accessoryCorner, .accessoryCircular, .accessoryInline, .accessoryRectangular,
        ])
        #else
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
        ])
        #endif
    }
}
