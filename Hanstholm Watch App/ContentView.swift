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
    @State private var surfEntry: SurfEntry?
    @State private var task: Task<Void, Never>?
    var isPreview = false
    
    var body: some View {
        Group {
            if let surfEntry {
                SurfSpot(surfEntry: surfEntry)
            } else {
                ProgressView()
            }
        }
        .task {
            guard isPreview else {
                return
            }
            
            surfEntry = try? await surfProvider.fetch()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                task = Task {
                    do {
                        surfEntry = try await surfProvider.fetch()
                    } catch {
                        logger.error("could not fetch: \(error)")
                    }
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
