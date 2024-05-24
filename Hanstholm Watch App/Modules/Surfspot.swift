//
//  Surfspot.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI
import DomainTypes
import MockData

struct SurfSpot: View {
    let surfEntry: SurfEntry
    
    var body: some View {
        switch surfEntry.status {
        case .error:
            Text("Sorry, there's a problem")
        case .initial:
            ProgressView()
        case .ok:
            Content(surfEntry: surfEntry)
        }
    }
}

extension SurfSpot {
    struct Content: View {
        let surfEntry: SurfEntry
        let gradient = Gradient(colors: [.green, .yellow, .orange, .red])
        
        var body: some View {
            TabView {
                WindView(name: surfEntry.name, wind: surfEntry.wind)
                    .navigationTitle("Wind")
                    .containerBackground(Color.accentColor.gradient, for: .tabView)
                WaveView()                    .navigationTitle("Wave")
                    .containerBackground(Color.accentColor.gradient, for: .tabView)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

#Preview {
    SurfSpot(
        surfEntry: MockData.SurfEntry.makeSurfEntry()
    )
}
