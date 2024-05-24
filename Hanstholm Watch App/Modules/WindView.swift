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
    let wind: SurfEntry.Wind
    
    var body: some View {
        ZStack {
            ProgressView(value: wind.speed.middle, total: wind.speed.gust)
                .progressViewStyle(GaugeProgressStyle())
            
            WindInfo(
                name: name,
                speed: wind.speed.current,
                maximum: wind.speed.gust,
                degrees: wind.direction.degrees
            )
        }
        .overlay(alignment: .bottom) {
            Text("km/h")
        }
        .fontDesign(.rounded)
    }
}

struct WindInfo: View {
    let name: String
    let speed: Double
    let maximum: Double
    let degrees: Double
    
    var locationDegrees: Double {
        degrees - 45
    }
    
    var body: some View {
        VStack{
            HStack {
                Image(systemName: "location.fill")
                    .rotationEffect(.degrees(locationDegrees))
                
                Text(name)
                    .font(.caption)
            }
    
            Text("\(speed.formatted())")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    WindView(
        name: "Hanstholm",
        wind: MockData.SurfEntry.makeWind()
    )
}
