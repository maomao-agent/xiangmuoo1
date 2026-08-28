import Foundation
import SwiftData

/// 首次启动写入默认分类与账户（PRD F1）
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        let categoryCount = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        if categoryCount == 0 {
            let expenses: [(String, String)] = [
                ("餐饮", "fork.knife"),
                ("购物", "bag"),
                ("交通", "car"),
                ("居住", "house"),
                ("娱乐", "gamecontroller"),
                ("医疗", "cross.case"),
                ("教育", "book"),
                ("人情", "gift"),
                ("其他", "ellipsis.circle"),
            ]
            let incomes: [(String, String)] = [
                ("工资", "banknote"),
                ("理财", "chart.line.uptrend.xyaxis"),
                ("退款", "arrow.uturn.left"),
                ("红包", "envelope"),
                ("其他", "ellipsis.circle"),
            ]
            for (index, item) in expenses.enumerated() {
                context.insert(Category(name: item.0, icon: item.1, isExpense: true, sort: index, isDefault: true))
            }
            for (index, item) in incomes.enumerated() {
                context.insert(Category(name: item.0, icon: item.1, isExpense: false, sort: index, isDefault: true))
            }
        }

        let accountCount = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0
        if accountCount == 0 {
            let accounts: [(String, AccountKind)] = [
                ("现金", .cash),
                ("微信", .wechat),
                ("支付宝", .alipay),
                ("银行卡", .bank),
            ]
            for (index, item) in accounts.enumerated() {
                context.insert(Account(name: item.0, kind: item.1, sort: index))
            }
        }

        try? context.save()
    }
}
