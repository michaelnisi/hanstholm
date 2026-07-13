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

    var body: some View {
        Group {
            if let surfEntry = surfProvider.surfEntry {
                SurfSpot(surfEntry: surfEntry)
            } else {
                ProgressView()
            }
        }
        .task {
            // `onChange(of: scenePhase)` below only fires on a *transition*, not for the
            // phase the app launches into, so the very first load has to happen here.
            await surfProvider.load()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                task = Task {
                    await surfProvider.load()
                }
                scheduleBackgroundRefresh()
            case .background, .inactive:
                task?.cancel()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .withMockProviders()
}
