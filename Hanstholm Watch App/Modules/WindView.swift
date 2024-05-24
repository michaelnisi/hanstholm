//
//  WindView.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI
import DomainTypes

struct WindView: View {
    @State private var progress = 0.2
    
    var body: some View {
        ZStack {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(GaugeProgressStyle())
            
            WindInfo(
                location: "Hanstholm",
                speed: 20.2,
                maximum: 35,
                degrees: Direction(cardinal: .southWest).degrees
            )
        }
        .overlay(alignment: .bottom) {
            Text("km/h")
        }
        .fontDesign(.rounded)
    }
}

struct WindInfo: View {
    let location: String
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
                
                Text(location)
                    .font(.caption)
            }
    
            Text("\(speed.formatted())")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    WindView()
}
