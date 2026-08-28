import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("明细", systemImage: "list.bullet.rectangle") }

            ContentUnavailableView("统计", systemImage: "chart.pie",
                                   description: Text("将在 M4 里程碑提供"))
                .tabItem { Label("统计", systemImage: "chart.pie") }

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .task { SeedData.seedIfNeeded(context: modelContext) }
    }
}
