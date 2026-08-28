import SwiftUI
import SwiftData
import SuishouCore

/// 明细页（PRD §4 首页）：月份切换 + 当月汇总 + 按日分组流水 + 搜索
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]

    @State private var month = Date()
    @State private var searchText = ""
    @State private var editing: Transaction?
    @State private var showingAdd = false

    init() {}

    private var calendar: Calendar { .current }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private var monthEnd: Date {
        calendar.date(byAdding: .month, value: 1, to: monthStart) ?? month
    }

    private var monthTransactions: [Transaction] {
        let inMonth = all.filter { $0.date >= monthStart && $0.date < monthEnd }
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return inMonth }
        return inMonth.filter { t in
            t.note.localizedCaseInsensitiveContains(keyword)
                || (t.merchant?.localizedCaseInsensitiveContains(keyword) ?? false)
                || (t.category?.name.localizedCaseInsensitiveContains(keyword) ?? false)
                || (t.account?.name.localizedCaseInsensitiveContains(keyword) ?? false)
                || Money.format(t.amount, showSymbol: false).contains(keyword)
        }
    }

    private var monthExpense: Decimal {
        monthTransactions.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var monthIncome: Decimal {
        monthTransactions.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var dayGroups: [(day: Date, items: [Transaction])] {
        let groups = Dictionary(grouping: monthTransactions) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { (day: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                summarySection

                if monthTransactions.isEmpty {
                    ContentUnavailableView("本月暂无账单", systemImage: "tray",
                                           description: Text("点下方“记一笔”开始记录"))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(dayGroups) { group in
                        Section {
                            ForEach(group.items) { item in
                                Button { editing = item } label: {
                                    TransactionRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in delete(group.items, at: offsets) }
                        } header: {
                            DayHeaderView(date: group.day,
                                          expense: group.items
                                              .filter { $0.type == .expense }
                                              .reduce(Decimal.zero) { $0 + $1.amount })
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "搜备注 / 分类 / 金额")
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
            .overlay(alignment: .bottom) {
                Button {
                    showingAdd = true
                } label: {
                    Label("记一笔", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.tint, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 12)
            }
            .sheet(isPresented: $showingAdd) { AddTransactionSheet() }
            .sheet(item: $editing) { transaction in
                AddTransactionSheet(editing: transaction)
            }
        }
    }

    // MARK: - 子视图

    private var summarySection: some View {
        Section {
            HStack(spacing: 0) {
                statItem("支出", Money.format(monthExpense), .primary)
                statItem("收入", Money.format(monthIncome), .green)
                statItem("结余", Money.format(monthIncome - monthExpense), .secondary)
            }
            .padding(.vertical, 6)
        }
    }

    private func statItem(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 操作

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthStart) {
            month = next
        }
    }

    private func delete(_ items: [Transaction], at offsets: IndexSet) {
        for index in offsets { modelContext.delete(items[index]) }
        try? modelContext.save()
    }
}

/// 单条流水行
struct TransactionRow: View {
    let item: Transaction

    private var title: String {
        if item.type == .transfer { return "转账" }
        return item.category?.name ?? "未分类"
    }

    private var subtitle: String {
        let parts: [String?] = [
            item.note.isEmpty ? nil : item.note,
            item.type == .transfer ? item.toAccount?.name : item.account?.name,
            item.date.formatted(date: .omitted, time: .shortened),
        ]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type == .transfer
                  ? "arrow.left.arrow.right"
                  : (item.category?.icon ?? "ellipsis.circle"))
                .font(.system(size: 17))
                .foregroundStyle(.tint)
                .frame(width: 38, height: 38)
                .background(Color(.systemGray6), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(amountText)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(amountColor)
        }
        .contentShape(Rectangle())
    }

    private var amountText: String {
        switch item.type {
        case .expense: return "-" + Money.format(item.amount)
        case .income: return "+" + Money.format(item.amount)
        case .transfer: return Money.format(item.amount)
        }
    }

    private var amountColor: Color {
        switch item.type {
        case .expense: return .primary
        case .income: return .green
        case .transfer: return .secondary
        }
    }
}

/// 日分组头：日期 + 当日支出小计（转账不计入）
struct DayHeaderView: View {
    let date: Date
    let expense: Decimal

    var body: some View {
        HStack {
            Text(Fmt.dayHeader(date))
            Spacer()
            Text("支出 \(Money.format(expense))")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
