//
//  ContentView.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 14.04.24.
//

import SwiftUI
import DomainTypes
import MockData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SurfProvider.self) var surfProvider
    @State private var task: Task<Void, Never>?
    var isPreview = false

    var body: some View {
        Group {
            if let surfEntry = surfProvider.surfEntry {
                SurfSpot(surfEntry: surfEntry)
            } else {
                ProgressView()
            }
        }
        .task {
            guard isPreview else {
                return
            }

            await surfProvider.load()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                task = Task {
                    await surfProvider.load()
                }
            case .background, .inactive:
                task?.cancel()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView(isPreview: true)
        .withMockProviders()
}
