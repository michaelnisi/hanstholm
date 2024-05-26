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
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var surfProvider: SurfProvider
    @State var surfEntry: SurfEntry?
    @State var task: Task<Void, Never>?
    
    var body: some View {
        Group {
            if let surfEntry {
                SurfSpot(surfEntry: surfEntry)
            } else {
                ProgressView()
            }
        }
        .task {
            update()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                update()
            case .background, .inactive:
                task?.cancel()
            @unknown default:
                break
            }
        }
    }
}

extension ContentView {
    private func update() {
        guard task == nil else {
            return
        }
        
        task = Task {
            do {
                surfEntry = try await surfProvider.fetch()
                task = nil
            } catch {
                logger.error("could not fetch: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
        .withMockProviders()
}
