import SwiftUI
import SwiftData
import Charts
import SuishouCore

/// 趋势图时间维度
enum TrendDimension: String, CaseIterable {
    case day
    case week
    case month

    var label: String {
        switch self {
        case .day: return "日"
        case .week: return "周"
        case .month: return "月"
        }
    }
}

/// 趋势图数据点
private struct TrendPoint: Identifiable {
    let label: String
    let value: Double
    var id: String { label }
}

/// 分类占比切片
private struct CategorySlice: Identifiable {
    let name: String
    let amount: Decimal
    let ratio: Double    // 0-100
    let color: Color
    var id: String { name }
}

/// 统计页（PRD F5 + 本次扩展）：月度汇总/环比同比、日周月趋势、分类环形图
struct StatisticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]

    @State private var month = Date()
    @State private var dimension: TrendDimension = .day

    private var calendar: Calendar { .current }

    // MARK: - 时间区间

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private var monthEnd: Date {
        calendar.date(byAdding: .month, value: 1, to: monthStart) ?? month
    }

    private var prevMonthRange: (start: Date, end: Date) {
        let start = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        return (start, monthStart)
    }

    private var lastYearRange: (start: Date, end: Date) {
        let start = calendar.date(byAdding: .year, value: -1, to: monthStart) ?? monthStart
        return (start, calendar.date(byAdding: .month, value: 1, to: start) ?? monthStart)
    }

    // MARK: - 汇总数据

    private var monthTransactions: [Transaction] {
        all.filter { $0.date >= monthStart && $0.date < monthEnd }
    }

    private var monthExpense: Decimal {
        monthTransactions.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var monthIncome: Decimal {
        monthTransactions.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var prevMonthExpense: Decimal {
        let range = prevMonthRange
        return all.filter { $0.type == .expense && $0.date >= range.start && $0.date < range.end }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var lastYearExpense: Decimal {
        let range = lastYearRange
        return all.filter { $0.type == .expense && $0.date >= range.start && $0.date < range.end }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// 环比/同比变化率（百分比）；基期为 0 时返回 nil
    private func changeRate(current: Decimal, previous: Decimal) -> Double? {
        guard previous > 0 else { return nil }
        let delta = (current - previous) / previous
        return NSDecimalNumber(decimal: delta).doubleValue * 100
    }

    // MARK: - 趋势数据

    private var trendPoints: [TrendPoint] {
        let expenses = monthTransactions.filter { $0.type == .expense }
        switch dimension {
        case .day:
            let days = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
            let byDay = Dictionary(grouping: expenses) { calendar.component(.day, from: $0.date) }
            return (1...days).map { day in
                let sum = (byDay[day] ?? []).reduce(Decimal.zero) { $0 + $1.amount }
                return TrendPoint(label: "\(day)", value: dbl(sum))
            }
        case .week:
            let byWeek = Dictionary(grouping: expenses) { calendar.component(.weekOfMonth, from: $0.date) }
            let weekCount = calendar.range(of: .weekOfMonth, in: .month, for: monthStart)?.count ?? 5
            return (1...weekCount).map { week in
                let sum = (byWeek[week] ?? []).reduce(Decimal.zero) { $0 + $1.amount }
                return TrendPoint(label: "第\(week)周", value: dbl(sum))
            }
        case .month:
            return (0..<6).reversed().map { offset in
                guard let start = calendar.date(byAdding: .month, value: -offset, to: monthStart),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else {
                    return TrendPoint(label: "", value: 0)
                }
                let sum = all.filter { $0.type == .expense && $0.date >= start && $0.date < end }
                    .reduce(Decimal.zero) { $0 + $1.amount }
                return TrendPoint(label: Fmt.monthShort(start), value: dbl(sum))
            }
        }
    }

    // MARK: - 分类占比

    private static let sliceColors: [Color] = [
        .blue, .orange, .green, .purple, .teal, .indigo, .gray,
    ]

    private var categorySlices: [CategorySlice] {
        let expenses = monthTransactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return [] }
        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "未分类" }
            .map { (name: $0.key, amount: $0.value.reduce(Decimal.zero) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }

        let top = grouped.prefix(6)
        let rest = grouped.dropFirst(6).reduce(Decimal.zero) { $0 + $1.amount }
        var result: [CategorySlice] = top.enumerated().map { index, item in
            CategorySlice(name: item.name,
                          amount: item.amount,
                          ratio: ratio(item.amount),
                          color: Self.sliceColors[index % Self.sliceColors.count])
        }
        if rest > 0 {
            result.append(CategorySlice(name: "其他", amount: rest, ratio: ratio(rest), color: .gray))
        }
        return result
    }

    private func ratio(_ amount: Decimal) -> Double {
        guard monthExpense > 0 else { return 0 }
        return NSDecimalNumber(decimal: amount / monthExpense).doubleValue * 100
    }

    // MARK: - 视图

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    summaryCard
                    trendCard
                    categoryCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(Fmt.month(month))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                }
            }
        }
    }

    // MARK: 汇总卡

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("本月支出")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Money.format(monthExpense))
                .font(.system(size: 36, weight: .bold, design: .rounded))

            HStack(spacing: 8) {
                changeBadge(title: "环比",
                            rate: changeRate(current: monthExpense, previous: prevMonthExpense))
                changeBadge(title: "同比",
                            rate: changeRate(current: monthExpense, previous: lastYearExpense))
            }

            Divider()

            HStack(spacing: 0) {
                miniStat("收入", Money.format(monthIncome), .green)
                miniStat("结余", Money.format(monthIncome - monthExpense), .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func miniStat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    /// 环比/同比徽章：支出上升显示红色、下降绿色、无基期灰色
    private func changeBadge(title: String, rate: Double?) -> some View {
        let color: Color = {
            guard let rate else { return .gray }
            return rate >= 0 ? .red : .green
        }()
        return HStack(spacing: 3) {
            Text(title).font(.caption2)
            if let rate {
                Image(systemName: rate >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: "%.1f%%", abs(rate)))
                    .font(.caption2.weight(.semibold))
            } else {
                Text("--").font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .foregroundStyle(color)
    }

    // MARK: 趋势卡

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("消费趋势").font(.headline)
                Spacer()
                Picker("维度", selection: $dimension) {
                    ForEach(TrendDimension.allCases, id: \.self) { d in
                        Text(d.label).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            Chart(trendPoints) { point in
                BarMark(
                    x: .value("时间", point.label),
                    y: .value("支出", point.value),
                    width: .ratio(0.62)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(3)
            }
            .frame(height: 180)
        }
        .cardStyle()
    }

    // MARK: 分类占比卡

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("分类占比").font(.headline)

            if categorySlices.isEmpty {
                ContentUnavailableView("本月暂无支出", systemImage: "chart.pie.fill",
                                       description: Text("记几笔账后再来看分析"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ZStack {
                    Chart(categorySlices) { slice in
                        SectorMark(
                            angle: .value("金额", slice.ratio),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.color)
                        .cornerRadius(3)
                    }
                    .frame(height: 190)

                    VStack(spacing: 2) {
                        Text("本月支出")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(Money.format(monthExpense))
                            .font(.system(.headline, design: .rounded))
                    }
                }

                ForEach(categorySlices) { slice in
                    HStack(spacing: 8) {
                        Circle().fill(slice.color).frame(width: 8, height: 8)
                        Text(slice.name).font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.ratio))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Money.format(slice.amount))
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .frame(minWidth: 92, alignment: .trailing)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - 工具

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthStart) {
            month = next
        }
    }

    private func dbl(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

// MARK: - 卡片样式

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}
