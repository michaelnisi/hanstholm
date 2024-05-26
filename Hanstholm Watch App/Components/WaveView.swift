//
//  WaveView.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI
import DomainTypes
import MockData

struct WaveView: View {
    let name: String
    let wave: SurfEntry.Wave
    
    var body: some View {
        ZStack {
            ProgressView(value: wave.middle, total: wave.max)
                .progressViewStyle(GaugeProgressStyle(strokeColor: .blue))
            
            WaveInfo(
                name: name,
                max: wave.max,
                middle: wave.middle,
                period: wave.period,
                degrees: wave.direction.degrees
            )
        }
        .overlay(alignment: .bottom) {
            Text("\(wave.period.seconds(width: .narrow))")
                .font(.headline)
        }
        .fontDesign(.rounded)
    }
}

struct WaveInfo: View {
    let name: String
    let max: Double
    let middle: Double
    let period: Double
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
    
            Text("\(middle.meters(width: .narrow))")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}
#Preview {
    WaveView(name: "Hanstholm", wave: MockData.SurfEntry.makeWave())
}
