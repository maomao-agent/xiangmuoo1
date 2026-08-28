import SwiftUI
import SwiftData

// MARK: - 分类管理（PRD：被流水引用的分类禁止物理删除）

struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sort)
    private var categories: [Category]

    @State private var adding = false
    @State private var editing: Category?
    @State private var denyMessage: String?

    init() {}

    var body: some View {
        List {
            Section("支出分类") { rows(isExpense: true) }
            Section("收入分类") { rows(isExpense: false) }
        }
        .navigationTitle("分类管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) { CategoryEditSheet() }
        .sheet(item: $editing) { CategoryEditSheet(editing: $0) }
        .alert("无法删除", isPresented: Binding(
            get: { denyMessage != nil },
            set: { if !$0 { denyMessage = nil } })) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(denyMessage ?? "")
        }
    }

    private func rows(isExpense: Bool) -> some View {
        ForEach(categories.filter { $0.isExpense == isExpense }) { category in
            Button { editing = category } label: {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .foregroundStyle(.tint)
                        .frame(width: 30)
                    Text(category.name)
                    Spacer()
                    Text("\(category.transactions.count) 笔")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
        }
        .onDelete { offsets in
            let list = categories.filter { $0.isExpense == isExpense }
            guard let index = offsets.first, index < list.count else { return }
            let category = list[index]
            if category.transactions.isEmpty {
                modelContext.delete(category)
                try? modelContext.save()
            } else {
                denyMessage = "「\(category.name)」已被 \(category.transactions.count) 笔流水使用，无法删除；可直接改名复用。"
            }
        }
    }
}

// MARK: - 分类编辑

struct CategoryEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let editing: Category?

    @State private var name = ""
    @State private var icon = "ellipsis.circle"
    @State private var isExpense = true

    static let iconChoices = [
        "fork.knife", "bag", "car", "house", "gamecontroller", "cross.case",
        "book", "gift", "ellipsis.circle", "banknote", "chart.line.uptrend.xyaxis",
        "arrow.uturn.left", "envelope", "airplane", "pawprint", "phone",
    ]

    init(editing: Category? = nil) {
        self.editing = editing
        guard let c = editing else { return }
        _name = State(initialValue: c.name)
        _icon = State(initialValue: c.icon)
        _isExpense = State(initialValue: c.isExpense)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称与类型") {
                    TextField("分类名称", text: $name)
                    Picker("类型", selection: $isExpense) {
                        Text("支出").tag(true)
                        Text("收入").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Self.iconChoices, id: \.self) { choice in
                            iconChoiceButton(choice)
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "新增分类" : "编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// 单个图标选项（拆分独立函数，避免长表达式类型推断超时）
    private func iconChoiceButton(_ choice: String) -> some View {
        let selected = icon == choice
        let background: Color = selected
            ? Color.accentColor.opacity(0.15)
            : Color(uiColor: .systemGray5)
        return Button {
            icon = choice
        } label: {
            Image(systemName: choice)
                .font(.system(size: 19))
                .frame(width: 40, height: 40)
                .background(background, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(selected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let c = editing {
            c.name = trimmed
            c.icon = icon
            c.isExpense = isExpense
        } else {
            modelContext.insert(Category(name: trimmed, icon: icon, isExpense: isExpense, sort: 999))
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - 账户管理

struct AccountManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sort) private var accounts: [Account]

    @State private var adding = false
    @State private var editing: Account?
    @State private var denyMessage: String?

    init() {}

    var body: some View {
        List {
            ForEach(accounts) { account in
                Button { editing = account } label: {
                    HStack(spacing: 12) {
                        Image(systemName: account.kind.icon)
                            .foregroundStyle(.tint)
                            .frame(width: 30)
                        Text(account.name)
                        Spacer()
                        Text("\(account.transactions.count + account.transfersIn.count) 笔")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .onDelete { offsets in
                guard let index = offsets.first, index < accounts.count else { return }
                let account = accounts[index]
                let used = account.transactions.count + account.transfersIn.count
                if used == 0 {
                    modelContext.delete(account)
                    try? modelContext.save()
                } else {
                    denyMessage = "「\(account.name)」已被 \(used) 笔流水使用，无法删除。"
                }
            }
        }
        .navigationTitle("账户管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) { AccountEditSheet() }
        .sheet(item: $editing) { account in AccountEditSheet(editing: account) }
        .alert("无法删除", isPresented: Binding(
            get: { denyMessage != nil },
            set: { if !$0 { denyMessage = nil } })) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(denyMessage ?? "")
        }
    }
}

// MARK: - 账户编辑

struct AccountEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let editing: Account?

    @State private var name = ""
    @State private var kind: AccountKind = .cash

    init(editing: Account? = nil) {
        self.editing = editing
        guard let a = editing else { return }
        _name = State(initialValue: a.name)
        _kind = State(initialValue: a.kind)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("账户名称", text: $name)
                Picker("类型", selection: $kind) {
                    ForEach(AccountKind.allCases, id: \.self) { k in
                        Label(k.label, systemImage: k.icon).tag(k)
                    }
                }
            }
            .navigationTitle(editing == nil ? "新增账户" : "编辑账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let a = editing {
            a.name = trimmed
            a.kindRaw = kind.rawValue
        } else {
            modelContext.insert(Account(name: trimmed, kind: kind, sort: 999))
        }
        try? modelContext.save()
        dismiss()
    }
}
