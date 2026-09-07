import WidgetKit
import SwiftUI
import Conditions
import DomainTypes
import MockData

struct PatrolWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: SurfEntry
    
    var body: some View {
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

    struct HomeSmall: View {
        var entry: SurfEntry

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(entry.wave.middle.feet()).fontWeight(.black)
                        + Text(" @ ") + Text(entry.wave.period.seconds())
                } icon: {
                    Image(systemName: "water.waves")
                }
                .font(.headline)

                DirectionLabel(
                    symbol: "location.fill",
                    degrees: entry.wind.direction.degrees,
                    text: "\(entry.wind.direction.formatted()) \(entry.wind.speed.current.knots())"
                )
                .font(.subheadline)

                Spacer(minLength: 0)

                HomeFooter(entry: entry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    struct HomeMedium: View {
        var entry: SurfEntry

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 16) {
                    waveColumn
                    Divider()
                    windColumn
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                HomeFooter(entry: entry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }

        private var waveColumn: some View {
            VStack(alignment: .leading, spacing: 2) {
                Label(entry.wave.middle.feet(), systemImage: "water.waves")
                    .font(.title3).fontWeight(.black)
                Text(entry.wave.period.seconds())
                    .font(.caption)
                DirectionLabel(
                    symbol: "location.fill",
                    degrees: entry.wave.direction.degrees,
                    text: entry.wave.direction.formatted()
                )
                .font(.caption)
            }
        }

        private var windColumn: some View {
            VStack(alignment: .leading, spacing: 2) {
                Label(entry.wind.speed.current.knots(), systemImage: "wind")
                    .font(.title3).fontWeight(.black)
                Text(entry.wind.speed.gust.knots())
                    .font(.caption)
                DirectionLabel(
                    symbol: "location.fill",
                    degrees: entry.wind.direction.degrees,
                    text: entry.wind.direction.formatted()
                )
                .font(.caption)
            }
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
                .containerBackground(.fill.tertiary, for: .widget)
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
