//
//  View+mockProviders.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI

extension View {
    @MainActor func withMockProviders() -> some View {
        self
            .environmentObject(SurfProvider.mock)
    }
}
