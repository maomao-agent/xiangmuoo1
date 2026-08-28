import SwiftUI
import SwiftData
import SuishouCore

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    /// 快捷指令经 URL Scheme 传入的入账参数（PRD F2）
    @State private var shortcutEntry: ShortcutEntry?

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
        .onOpenURL { url in
            if let entry = ShortcutParser.parse(url) {
                shortcutEntry = entry
            }
        }
        // 预确认卡片：金额/备注已预填，点分类即保存
        .sheet(item: $shortcutEntry) { entry in
            AddTransactionSheet(preset: entry)
        }
    }
}
