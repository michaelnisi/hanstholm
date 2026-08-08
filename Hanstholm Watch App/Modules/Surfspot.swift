import SwiftUI
import DomainTypes
import MockData

struct SurfSpot: View {
    let surfEntry: SurfEntry
    
    var body: some View {
        TabView {
            WindView(name: surfEntry.place.name, date: surfEntry.date, wind: surfEntry.wind)
                .containerBackground(Color.accentColor.gradient, for: .tabView)
            
            WaveView(name: surfEntry.place.name, date: surfEntry.date, wave: surfEntry.wave)
                .containerBackground(Color.accentColor.gradient, for: .tabView)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    SurfSpot(
        surfEntry: MockData.SurfEntry.makeSurfEntry()
    )
}
