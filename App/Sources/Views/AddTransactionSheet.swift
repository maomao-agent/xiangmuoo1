import SwiftUI
import SwiftData
import Core

/// 记账 / 编辑页（PRD F4：3 秒手动记账 —— 大数字键盘 + 分类宫格）
struct AddTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.sort) private var categories: [Category]
    @Query(sort: \Account.sort) private var accounts: [Account]

    private let editing: Transaction?

    @State private var type: TransactionType = .expense
    @State private var amountString = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var categoryID: UUID?
    @State private var accountID: UUID?
    @State private var toAccountID: UUID?

    @FocusState private var noteFocused: Bool

    init(editing: Transaction? = nil) {
        self.editing = editing
        guard let t = editing else { return }
        _type = State(initialValue: t.type)
        _amountString = State(initialValue: Money.format(t.amount, showSymbol: false)
            .replacingOccurrences(of: ",", with: ""))
        _note = State(initialValue: t.note)
        _date = State(initialValue: t.date)
        _categoryID = State(initialValue: t.category?.uid)
        _accountID = State(initialValue: t.account?.uid)
        _toAccountID = State(initialValue: t.toAccount?.uid)
    }

    // MARK: - 派生值

    private var amount: Decimal? { Money.decimal(fromKeypadString: amountString) }

    private var availableCategories: [Category] {
        categories.filter { $0.isExpense == (type == .expense) }
    }

    /// 类型切换后旧分类不再匹配（如支出分类配收入类型）→ 视为未选
    private var selectedCategory: Category? {
        categories.first { $0.uid == categoryID && $0.isExpense == (type == .expense) }
    }

    private var selectedAccount: Account? {
        accounts.first { $0.uid == accountID }
    }

    private var selectedToAccount: Account? {
        accounts.first { $0.uid == toAccountID }
    }

    private var canSave: Bool {
        guard let amt = amount, amt > 0 else { return false }
        switch type {
        case .expense, .income:
            return selectedCategory != nil
        case .transfer:
            guard let from = selectedAccount, let to = selectedToAccount else { return false }
            return from.uid != to.uid
        }
    }

    // MARK: - 视图

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("类型", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    amountHeader

                    if type == .transfer {
                        transferSection
                    } else {
                        categorySection
                        accountMenu("账户", selection: $accountID)
                    }

                    noteAndDateSection
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .safeAreaInset(edge: .bottom) {
                // 备注输入时让位给系统键盘，其余时候常驻大数字键盘
                if !noteFocused { KeypadView(text: $amountString) }
            }
            .navigationTitle(editing == nil ? "记一笔" : "编辑账单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "保存" : "更新") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var amountHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("¥")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(amountString.isEmpty ? "0" : amountString)
                .font(.system(size: 46, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var categorySection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(availableCategories) { c in
                categoryCell(c)
            }
        }
    }

    /// 单个分类宫格（拆成独立函数，避免长表达式类型推断超时）
    private func categoryCell(_ c: Category) -> some View {
        let selected = c.uid == categoryID
        let background: Color = selected
            ? Color.accentColor.opacity(0.15)
            : Color(uiColor: .systemGray6)
        return Button {
            categoryID = selected ? nil : c.uid
        } label: {
            VStack(spacing: 6) {
                Image(systemName: c.icon).font(.system(size: 19))
                Text(c.name).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(background, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(selected ? .tint : .primary)
        }
        .buttonStyle(.plain)
    }

    private var transferSection: some View {
        VStack(spacing: 10) {
            accountMenu("转出账户", selection: $accountID)
            Image(systemName: "arrow.down")
                .font(.caption)
                .foregroundStyle(.secondary)
            accountMenu("转入账户", selection: $toAccountID)
        }
    }

    private var noteAndDateSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.line").foregroundStyle(.secondary)
                TextField("备注（可选）", text: $note)
                    .focused($noteFocused)
            }
            .padding(12)
            .background(Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 12))

            DatePicker("时间", selection: $date)
                .padding(12)
                .background(Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func accountMenu(_ title: String, selection: Binding<UUID?>) -> some View {
        Menu {
            Picker(title, selection: selection) {
                Text("未选择").tag(UUID?.none)
                ForEach(accounts) { account in
                    Text(account.name).tag(account.uid as UUID?)
                }
            }
        } label: {
            let current = accounts.first { $0.uid == selection.wrappedValue }
            return HStack(spacing: 10) {
                Image(systemName: current?.kind.icon ?? "creditcard")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(current?.name ?? "未选择").font(.body)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 保存

    private func save() {
        guard let amt = amount, amt > 0 else { return }
        if let t = editing {
            t.amount = amt
            t.type = type
            t.date = date
            t.note = note
            t.category = selectedCategory
            t.account = selectedAccount
            t.toAccount = type == .transfer ? selectedToAccount : nil
            t.updatedAt = .now
        } else {
            let t = Transaction(amount: amt,
                                type: type,
                                date: date,
                                note: note,
                                source: .manual,
                                category: selectedCategory,
                                account: selectedAccount,
                                toAccount: type == .transfer ? selectedToAccount : nil)
            modelContext.insert(t)
        }
        try? modelContext.save()
        dismiss()
    }
}
