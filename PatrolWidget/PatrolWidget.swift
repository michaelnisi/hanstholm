import WidgetKit
import SwiftUI
import Conditions
import DomainTypes
import MockData
import SurfUI
#if canImport(UIKit)
import UIKit
#endif

struct PatrolWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: SurfEntry

    var body: some View {
        familyView
            .containerBackground(for: .widget) {
                TileBackground(family: widgetFamily)
            }
    }

    @ViewBuilder
    private var familyView: some View {
        switch widgetFamily {
        #if os(watchOS)
        case .accessoryCorner:
            if entry.status == .error {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "exclamationmark.triangle")
                }
                .widgetLabel {
                    Text("No Data")
                }
            } else {
                AccessoryCorner(entry: entry)
            }
        #else
        case .systemSmall:
            if entry.status == .error {
                NoDataHomeTile()
            } else {
                HomeSmall(entry: entry)
            }
        case .systemMedium:
            if entry.status == .error {
                NoDataHomeTile()
            } else {
                HomeMedium(entry: entry)
            }
        #endif
        case .accessoryCircular:
            if entry.status == .error {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "exclamationmark.triangle")
                }
                .widgetAccentable()
            } else {
                AccessoryCircular(entry: entry)
            }
        case .accessoryInline:
            if entry.status == .error {
                Text("No Data")
            } else {
                AccessoryInline(entry: entry)
            }
        case .accessoryRectangular:
            if entry.status == .error {
                Label("No Data", systemImage: "exclamationmark.triangle")
                    .widgetAccentable()
            } else {
                AccessoryRectangular(entry: entry)
            }
        default:
            AccessoryInline(entry: entry)
        }
    }
}

struct TileBackground: View {
    var family: WidgetFamily

    var body: some View {
        switch family {
        #if !os(watchOS)
        case .systemSmall, .systemMedium:
            Rectangle().fill(Color(uiColor: .systemBackground).gradient)
        #endif
        default:
            Rectangle().fill(.fill.tertiary)
        }
    }
}

extension PatrolWidgetEntryView {
    #if !os(watchOS)
    struct HomeFooter: View {
        var entry: SurfEntry

        var body: some View {
            Text("\(entry.place.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    struct GaugeReadout: View {
        var symbol: String
        var value: String
        var caption: String
        var direction: Direction

        var body: some View {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.black)
                HStack(spacing: 3) {
                    DirectionIndicator(
                        degrees: direction.degrees,
                        formatted: direction.formatted()
                    )
                    Text(caption)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .cappedDynamicType()
        }
    }

    struct NoDataHomeTile: View {
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                Text("No Data")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    struct HomeSmall: View {
        var entry: SurfEntry

        var body: some View {
            SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
                GaugeReadout(
                    symbol: "water.waves",
                    value: entry.wave.middle.feet(),
                    caption: entry.wave.period.seconds(),
                    direction: entry.wave.direction
                )
            }
            .overlay(alignment: .bottom) {
                Text("\(entry.wind.direction.formatted()) \(entry.wind.speed.current.knots())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .cappedDynamicType()
            }
            .fontDesign(.rounded)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(entry.wave.spoken), and \(entry.wind.spoken).")
        }
    }

    struct HomeMedium: View {
        var entry: SurfEntry

        var body: some View {
            VStack(spacing: 6) {
                HStack(spacing: 24) {
                    Spacer()
                    SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
                        GaugeReadout(
                            symbol: "water.waves",
                            value: entry.wave.middle.feet(),
                            caption: entry.wave.period.seconds(),
                            direction: entry.wave.direction
                        )
                    }
                    Spacer()
                    SurfGauge(
                        value: entry.wind.speed.middle,
                        total: entry.wind.speed.gust ?? entry.wind.speed.middle,
                        tint: .teal
                    ) {
                        GaugeReadout(
                            symbol: "wind",
                            value: entry.wind.speed.current.knots(),
                            caption: entry.wind.speed.gust.knots(),
                            direction: entry.wind.direction
                        )
                    }
                    Spacer()
                }

                HomeFooter(entry: entry)
            }
            .fontDesign(.rounded)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.spokenSummary)
        }
    }
    #endif

    #if os(watchOS)
    struct AccessoryCorner: View {
        var entry: SurfEntry

        var body: some View {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "water.waves")
                    .font(.title.bold())
                    .widgetAccentable()
            }
            .widgetLabel {
                Text(entry.wave.middle.feet() + " @ " + entry.wave.period.seconds())
                    .accessibilityLabel(entry.wave.spoken)
            }
        }
    }
    #endif

    struct AccessoryCircular: View {
        var entry: SurfEntry
        
        var body: some View {
            ZStack {
                AccessoryWidgetBackground()
                VStack {
                    Text(entry.wave.middle.feet(width: .narrow))
                    Text(entry.wave.period.seconds(width: .narrow))
                }
                .widgetAccentable()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.wave.spoken)
        }
    }
    
    struct AccessoryInline: View {
        var entry: SurfEntry
        
        var body: some View {
            Text("\(entry.wave.middle.feet()) @ \(entry.wave.period.seconds())")
        }
    }
    
    struct AccessoryRectangular: View {
        var entry: SurfEntry
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("\(Image(systemName: "water.waves")) \(Text(entry.wave.middle.feet()).fontWeight(.black)) @ \(entry.wave.period.seconds())")

                Text("\(Image(systemName: "wind")) \(Text(entry.wind.direction.formatted()).fontWeight(.black)) \(entry.wind.speed.current.knots())")
               
                Text("\(entry.place.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            .widgetAccentable()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.spokenSummary)
        }
    }
}

@main
struct PatrolWidget: Widget {
    let kind: String = "PatrolWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SurfEntryProvider()) { entry in
            PatrolWidgetEntryView(entry: entry)
        }
        .onBackgroundURLSessionEvents(
            matching: DeferredDownloadConfiguration.defaultSessionIdentifier()
        ) { urlSessionEvent, completion in
            ConditionsCoordinator.widget.handleBackgroundSessionEvents {
                completion()
            }
        }
        .configurationDisplayName("Patrol")
        .description("Vejret Hanstholm Havn")
        #if os(watchOS)
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryInline, .accessoryRectangular])
        #else
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
        #endif
    }
}



#Preview(as: .accessoryRectangular) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}

#Preview("No Data", as: .accessoryRectangular) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry(status: .error)
}

#if !os(watchOS)
#Preview(as: .systemSmall) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}

#Preview("No Data", as: .systemSmall) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry(status: .error)
}

#Preview(as: .systemMedium) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}

#Preview("No Data", as: .systemMedium) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry(status: .error)
}
#endif
