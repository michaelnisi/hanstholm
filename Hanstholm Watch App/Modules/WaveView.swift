//
//  WaveView.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 12.05.24.
//

import SwiftUI

struct WaveView: View {
    var body: some View {
        Gauge(value: 1.5, in: 0...2) {
            Text("BPM")
        } currentValueLabel: {
            Text("1.5m")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("2")
        }
        .gaugeStyle(.circular)
    }
}

#Preview {
    WaveView()
}
