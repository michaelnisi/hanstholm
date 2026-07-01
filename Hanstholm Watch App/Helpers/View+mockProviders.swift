//
//  View+mockProviders.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI

extension View {
    func withMockProviders() -> some View {
        self
            .environment(SurfProvider.mock)
    }
}
