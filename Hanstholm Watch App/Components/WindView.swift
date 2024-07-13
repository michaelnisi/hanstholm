//
//  WindView.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI
import DomainTypes
import MockData

struct WindView: View {
    let name: String
    let date: Date
    let wind: SurfEntry.Wind
    
    var body: some View {
        ZStack {
            ProgressView(value: wind.speed.middle, total: wind.speed.gust)
                .progressViewStyle(GaugeProgressStyle(strokeColor: .teal))
            
            WindInfo(
                name: name,
                date: date,
                speed: wind.speed.current,
                maximum: wind.speed.gust,
                degrees: wind.direction.degrees
            )
        }
        .overlay(alignment: .bottom) {
            Text("\(wind.speed.gust.metersPerSecond(width: .narrow))")
                .font(.headline)
        }
        .fontDesign(.rounded)
    }
}

struct WindInfo: View {
    let name: String
    let date: Date
    let speed: Double
    let maximum: Double
    let degrees: Double

    var locationDegrees: Double {
        degrees - 45
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "location.fill")
                    .rotationEffect(.degrees(locationDegrees))
                
                Text(name)
                    .font(.caption)
            }
            
            Text("\(speed.metersPerSecond(width: .narrow))")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.teal)
        }
    }
}

#Preview {
    WindView(
        name: "Hanstholm",
        date: .now,
        wind: MockData.SurfEntry.makeWind()
    )
}
