//
//  GaugeProgressStyle.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 24.05.24.
//

import SwiftUI

struct GaugeProgressStyle: ProgressViewStyle {
    var strokeColor = Color.blue
    var strokeWidth = 20.0
    
    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0
        let x = fractionCompleted * 0.766
        
        return ZStack {
            Circle()
                .trim(from: 0, to: 0.766)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .opacity(0.3)
                .rotationEffect(.degrees(135))
            
            Circle()
                .trim(from: 0, to: x)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
        }
    }
}
