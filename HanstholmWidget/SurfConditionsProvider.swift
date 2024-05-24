//
//  SurfConditionsProvider.swift
//  HanstholmWidgetExtension
//
//  Created by Michael Nisi on 28.04.24.
//

import WidgetKit
import SwiftUI
import Hyde

struct SurfEntryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SurfEntry {
        .init(
            date: .now,
            status: .ok,
            wave: .init(
                height: 1.2,
                period: 12
            ),
            wind: .init(
                strength: 6,
                direction: "SW"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SurfEntry) -> ()) {
        Task {
            var hyde = Hyde.backgroundResult()
            
            if hyde == nil {
                hyde = try? await Hyde.fetch()
            }
            
            let entry = SurfEntry(dto: hyde)
            
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SurfEntry>) -> ()) {
        Hyde.backgroundFetch()
        
        Task {
            var hyde = Hyde.backgroundResult()
            
            if hyde == nil {
                hyde = try? await Hyde.fetch()
            }
            
            let entry = SurfEntry(dto: hyde)
            let entries = [entry]
            // Relying completely on the background fetch for now.
            let timeline = Timeline(entries: entries, policy: .never)
            
            completion(timeline)
        }
    }
}

struct SurfEntry: TimelineEntry {
    enum Status {
        case ok, error, initial
    }
   
    struct Wave {
        let height: Double
        let period: Double
    }
    
    struct Wind {
        let strength: Double
        let direction: String
    }
    
    let date: Date
    let status: Status
    let wave: Wave
    let wind: Wind
    
    init(date: Date, status: Status, wave: Wave, wind: Wind) {
        self.date = date
        self.status = status
        self.wave = wave
        self.wind = wind
    }
}

extension SurfEntry {
    init(dto: Hyde?) {
        guard let dto else {
            self.date = .now
            self.status = .error
            self.wave = .init(height: 0, period: 0)
            self.wind = .init(strength: 0, direction: "")
            
            return
        }
        
        self.date = dto.date
        self.status = .ok
        self.wave = .init(height: dto.wave.height, period: dto.wave.period)
        self.wind = .init(strength: dto.wind.strength, direction: dto.wind.direction)
    }
}

extension SurfEntry {
    init() {
        self.date = .now
        self.status = .initial
        self.wave = .init(height: 0, period: 0)
        self.wind = .init(strength: 0, direction: "")
    }
}
