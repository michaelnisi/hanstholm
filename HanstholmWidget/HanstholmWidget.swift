//
//  HanstholmWidget.swift
//  HanstholmWidget
//
//  Created by Michael Nisi on 14.04.24.
//

import WidgetKit
import SwiftUI
import Hyde
import DomainTypes
import MockData

struct HanstholmWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: SurfEntry
    
    var body: some View {
        switch widgetFamily {
        #if os(watchOS)
        case .accessoryCorner:
            AccessoryCorner(entry: entry)
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

extension HanstholmWidgetEntryView {
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
               
                Text("\(entry.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            .widgetAccentable()
        }
    }
}

@main
struct HanstholmWidget: Widget {
    let kind: String = "HanstholmWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SurfEntryProvider()) { entry in
            if #available(watchOS 10.0, *) {
                HanstholmWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HanstholmWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .onBackgroundURLSessionEvents(matching: "hyde.dk") { urlSessionEvent, completion in
            Task {
                await Hyde.setCompletion {
                    MainActor.assumeIsolated {
                        completion()
                    }
                }
            }
        }
        .configurationDisplayName("Hanstholm")
        .description("Vejret Hanstholm Havn")
        #if os(watchOS)
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryInline, .accessoryRectangular])
        #else
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
        #endif
    }
}



#Preview(as: .accessoryRectangular) {
    HanstholmWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}
