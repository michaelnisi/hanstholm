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
    @EnvironmentObject var surfProvider: SurfProvider
    @State var surfEntry: SurfEntry?
    
    var body: some View {
        Group {
            if let surfEntry {
                SurfSpot(surfEntry: surfEntry)
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                surfEntry = try await surfProvider.fetch()
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
