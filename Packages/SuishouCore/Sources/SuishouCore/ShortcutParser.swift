import Foundation

/// 快捷指令传入的入账参数（经 URL 到达，见 PRD F2）
public struct ShortcutEntry: Identifiable, Equatable {
    public let id: UUID
    public let amount: Decimal
    public let note: String
    /// "expense" 或 "income"（解析时已归一化，非法值按 expense 处理）
    public let type: String
    /// Unix 秒级时间戳；缺省为 nil（App 侧用当前时间）
    public let date: Date?

    public init(id: UUID = UUID(), amount: Decimal, note: String, type: String, date: Date? = nil) {
        self.id = id
        self.amount = amount
        self.note = note
        self.type = type
        self.date = date
    }
}

/// 解析 suishouzhang://add?amount=38.5&note=xx&type=expense&date=1700000000
/// 纯逻辑，可在 Linux 上单测
public enum ShortcutParser {

    public static let scheme = "suishouzhang"

    public static func parse(_ url: URL) -> ShortcutEntry? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        let action = (url.host ?? url.pathComponents.last ?? "").lowercased()
        guard action == "add" else { return nil }
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        let items = comps.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard let amountText = value("amount"),
              let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: "")),
              amount > 0 else { return nil }

        let note = value("note") ?? ""
        let rawType = (value("type") ?? "expense").lowercased()
        let type = rawType == "income" ? "income" : "expense"

        var date: Date?
        if let ts = value("date"), let seconds = Double(ts) {
            date = Date(timeIntervalSince1970: seconds)
        }
        return ShortcutEntry(amount: amount, note: note, type: type, date: date)
    }
}
