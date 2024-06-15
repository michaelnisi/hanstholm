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
        case .accessoryCorner:
            AccessoryCorner(entry: entry)
        case .accessoryCircular:
            AccessoryCircular(entry: entry)
        case .accessoryInline:
            AccessoryInline(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangular(entry: entry)
        @unknown default:
            AccessoryInline(entry: entry)
        }
    }
}

extension HanstholmWidgetEntryView {
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
                Text(entry.wave.middle.meters() + " @ " + entry.wave.period.seconds())
            }
        }
    }
    
    struct AccessoryCircular: View {
        var entry: SurfEntry
        
        var body: some View {
            ZStack {
                AccessoryWidgetBackground()
                VStack {
                    Text(entry.wave.middle.meters(width: .narrow))
                    Text(entry.wave.period.seconds(width: .narrow))
                }
                .widgetAccentable()
            }
        }
    }
    
    struct AccessoryInline: View {
        var entry: SurfEntry
        
        var body: some View {
            Text("\(entry.wave.middle.meters()) @ \(entry.wave.period.seconds())")
        }
    }
    
    struct AccessoryRectangular: View {
        var entry: SurfEntry
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(Image(systemName: "water.waves")) + Text(" ") + Text(entry.wave.middle.meters()).fontWeight(.black) + Text(" @ ") + Text(entry.wave.period.seconds())
                
                Text(Image(systemName: "wind")) + Text(" ") + Text(entry.wind.direction.formatted()).fontWeight(.black) + Text(" ") + Text(entry.wind.speed.current.metersPerSecond())
                
                Text(entry.name)
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
        .onBackgroundURLSessionEvents(matching: "www.hyde.dk") { urlSessionEvent, completion in
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
    }
}



#Preview(as: .accessoryRectangular) {
    HanstholmWidget()
} timeline: {
    MockData.SurfEntry.makeSurfEntry()
}
