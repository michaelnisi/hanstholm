//
//  ContentView.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 14.04.24.
//

import SwiftUI
import DomainTypes
import MockData
import Puddles

struct ContentView: View {
    @EnvironmentObject private var surfProvider: SurfProvider
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationSplitView {
            List(surfProvider.entries, selection: $surfProvider.selected) { surfEntry in
                Text(surfEntry.name)
                    .tag(surfEntry)
            }
        } detail: {
            if let selected = surfProvider.selected {
                SurfSpot(surfEntry: selected)
                    .onAppear {
                        Task {
                            try? await surfProvider.update()
                        }
                    }
            } else {
                Text("Sorry")
            }
        }
        .task {
            try? await surfProvider.update()
        }
    }
}

#Preview {
    ContentView()
        .withMockProviders()
}
