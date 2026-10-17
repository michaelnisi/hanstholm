import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Places", systemImage: "water.waves") {
                PlacesView()
            }
        }
    }
}

#Preview {
    ContentView()
}
