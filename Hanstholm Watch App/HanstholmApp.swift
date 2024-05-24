//
//  HanstholmApp.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 14.04.24.
//

import SwiftUI
import MockData
import Puddles
import os.log

let logger = Logger(subsystem: "ink.codes.hanstholm", category: "App")

@main
struct Hanstholm_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SurfProvider.live)
        }
    }
}
