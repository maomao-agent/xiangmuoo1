import SwiftUI
import SwiftData

@main
struct SuishouApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Transaction.self, Category.self, Account.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("数据库初始化失败：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
