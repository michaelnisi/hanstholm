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
        TabView {
            WindView(name: surfEntry.name, wind: surfEntry.wind)
                .containerBackground(Color.accentColor.gradient, for: .tabView)
            
            WaveView(name: surfEntry.name, wave: surfEntry.wave)
                .containerBackground(Color.accentColor.gradient, for: .tabView)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    SurfSpot(
        surfEntry: MockData.SurfEntry.makeSurfEntry()
    )
}
