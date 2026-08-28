import Foundation

/// 集中管理日期/时间展示格式（中文）
enum Fmt {
    private static let zh = Locale(identifier: "zh_CN")

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zh
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zh
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let weekDays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    static func month(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    /// 短月份标签，如 "8月"（趋势图用）
    static func monthShort(_ date: Date) -> String {
        "\(calendarMonth(date))月"
    }

    private static func calendarMonth(_ date: Date) -> Int {
        Calendar.current.component(.month, from: date)
    }

    static func dayHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        let week = weekDays[calendar.component(.weekday, from: date) - 1]
        return dayFormatter.string(from: date) + " " + week
    }
}
