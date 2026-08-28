import Foundation

/// 金额工具：键盘输入规则 + 解析 + 展示格式化（纯逻辑，无 UI 依赖）
public enum Money {

    public static let symbol = "¥"

    /// 键盘输入规则：返回追加 input 后的合法金额字符串，非法输入返回原串
    /// 规则（PRD F4）：仅一个小数点、最多 2 位小数、最多 9 位整数、无前导零
    public static func keypad(_ current: String, appending input: String) -> String {
        switch input {
        case ".":
            if current.contains(".") { return current }
            return current.isEmpty ? "0." : current + "."
        case "⌫":
            return String(current.dropLast())
        default:
            guard input.count == 1, input.first?.isNumber == true else { return current }
            if let dot = current.firstIndex(of: ".") {
                let frac = current[current.index(after: dot)...]
                guard frac.count < 2 else { return current }
                return current + input
            } else {
                guard current.count < 9 else { return current }
                if current == "0" { return input }   // "0" 再按数字 → 替换，避免前导零
                return current + input
            }
        }
    }

    /// 键盘字符串 → Decimal；非法（空、尾点、多点、非数字）返回 nil
    public static func decimal(fromKeypadString s: String) -> Decimal? {
        guard !s.isEmpty, !s.hasSuffix(".") else { return nil }
        let parts = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return nil }
        let intPart = parts[0]
        let fracPart = parts.count == 2 ? parts[1] : ""
        guard intPart.allSatisfy(\.isNumber), fracPart.allSatisfy(\.isNumber) else { return nil }
        return Decimal(string: s)
    }

    /// Decimal → "¥1,234.56"（千分位分组 + 固定两位小数，负数前加 -）
    public static func format(_ value: Decimal, showSymbol: Bool = true) -> String {
        let negative = value < 0
        let magnitude = negative ? -value : value
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2,
                                             raiseOnExactness: false, raiseOnOverflow: false,
                                             raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let plain = NSDecimalNumber(decimal: magnitude)
            .rounding(accordingToBehavior: handler)
            .stringValue
        let parts = plain.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let intRaw = parts[0]
        let fracRaw = parts.count > 1 ? parts[1] : ""
        let frac = String((fracRaw + "00").prefix(2))
        var grouped = ""
        var inserted = 0
        for ch in intRaw.reversed() {
            if inserted > 0 && inserted % 3 == 0 { grouped = "," + grouped }
            grouped = String(ch) + grouped
            inserted += 1
        }
        let sign = negative ? "-" : ""
        return sign + (showSymbol ? symbol : "") + grouped + "." + frac
    }
}
