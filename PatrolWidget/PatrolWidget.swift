import WidgetKit
import SwiftUI
import Conditions
import DomainTypes
import MockData
import SurfUI

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
            AccessoryCorner(entry: entry)
        #else
        case .systemSmall:
            HomeSmall(entry: entry)
        case .systemMedium:
            HomeMedium(entry: entry)
        #endif
        case .accessoryCircular:
            AccessoryCircular(entry: entry)
        case .accessoryInline:
            AccessoryInline(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangular(entry: entry)
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
            Color.clear
        #endif
        default:
            Rectangle().fill(.fill.tertiary)
        }
    }
}

extension PatrolWidgetEntryView {
    #if !os(watchOS)
    struct DirectionLabel: View {
        var symbol: String
        var degrees: Double
        var text: String

        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .rotationEffect(.degrees(degrees - 45))
                Text(text)
            }
        }
    }

    struct HomeFooter: View {
        var entry: SurfEntry

        var body: some View {
            Text("\(entry.place.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    struct SurfGauge<Label: View>: View {
        var value: Double
        var total: Double
        var tint: Color
        var strokeWidth: Double = 14
        @ViewBuilder var label: () -> Label

        var body: some View {
            ProgressView(
                value: max(0, min(value, total)),
                total: total > 0 ? total : 1
            )
            .progressViewStyle(GaugeProgressStyle(strokeColor: tint, strokeWidth: strokeWidth))
            .overlay { label() }
        }
    }

    struct GaugeReadout: View {
        var value: String
        var caption: String
        var degrees: Double

        var body: some View {
            VStack(spacing: 1) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.black)
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(degrees - 45))
            }
        }
    }

    struct HomeSmall: View {
        var entry: SurfEntry

        var body: some View {
            SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
                VStack(spacing: 1) {
                    Text(entry.wave.middle.feet())
                        .font(.title)
                        .fontWeight(.black)
                    Text(entry.wave.period.seconds())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay(alignment: .bottom) {
                DirectionLabel(
                    symbol: "location.fill",
                    degrees: entry.wind.direction.degrees,
                    text: "\(entry.wind.direction.formatted())  \(entry.wind.speed.current.knots())"
                )
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            }
            .fontDesign(.rounded)
        }
    }

    struct HomeMedium: View {
        var entry: SurfEntry

        var body: some View {
            VStack(spacing: 6) {
                HStack(spacing: 24) {
                    SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
                        GaugeReadout(
                            value: entry.wave.middle.feet(),
                            caption: entry.wave.period.seconds(),
                            degrees: entry.wave.direction.degrees
                        )
                    }

                    SurfGauge(
                        value: entry.wind.speed.middle,
                        total: entry.wind.speed.gust ?? entry.wind.speed.middle,
                        tint: .teal
                    ) {
                        GaugeReadout(
                            value: entry.wind.speed.current.knots(),
                            caption: entry.wind.speed.gust.knots(),
                            degrees: entry.wind.direction.degrees
                        )
                    }
                }

                HomeFooter(entry: entry)
            }
            .fontDesign(.rounded)
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
                Text(Image(systemName: "water.waves")) + Text(" ") + Text(entry.wave.middle.feet()).fontWeight(.black) + Text(" @ ") + Text(entry.wave.period.seconds())
                
                Text(Image(systemName: "wind")) + Text(" ") + Text(entry.wind.direction.formatted()).fontWeight(.black) + Text(" ") + Text(entry.wind.speed.current.knots())
               
                Text("\(entry.place.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            .widgetAccentable()
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

#if !os(watchOS)
#Preview(as: .systemSmall) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}

#Preview(as: .systemMedium) {
    PatrolWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}
#endif
