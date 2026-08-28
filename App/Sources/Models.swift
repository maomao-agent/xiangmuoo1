import Foundation
import SwiftData

/// 流水类型
enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
    case transfer

    var label: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        case .transfer: return "转账"
        }
    }
}

/// 入账来源（PRD F2 快捷指令 / F3 账单导入 / F4 手动）
enum EntrySource: String, Codable {
    case manual
    case shortcut
    case imported
}

/// 账户类型
enum AccountKind: String, Codable, CaseIterable {
    case cash
    case wechat
    case alipay
    case bank

    var label: String {
        switch self {
        case .cash: return "现金"
        case .wechat: return "微信"
        case .alipay: return "支付宝"
        case .bank: return "银行卡"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "banknote"
        case .wechat: return "message.fill"
        case .alipay: return "qrcode"
        case .bank: return "creditcard"
        }
    }
}

/// 分类（支出/收入共用一张表，isExpense 区分；PRD §5）
@Model
final class Category {
    var name: String
    var icon: String        // SF Symbol 名称
    var isExpense: Bool
    var sort: Int
    var isDefault: Bool

    // PRD：分类被流水引用时禁止物理删除 → deleteRule .deny + 界面层校验
    @Relationship(deleteRule: .deny, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    init(name: String, icon: String, isExpense: Bool, sort: Int = 0, isDefault: Bool = false) {
        self.name = name
        self.icon = icon
        self.isExpense = isExpense
        self.sort = sort
        self.isDefault = isDefault
    }
}

/// 账户（现金/微信/支付宝/银行卡）
@Model
final class Account {
    var name: String
    var kindRaw: String
    var sort: Int

    @Relationship(deleteRule: .deny, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .deny, inverse: \Transaction.toAccount)
    var transfersIn: [Transaction] = []

    var kind: AccountKind { AccountKind(rawValue: kindRaw) ?? .cash }

    init(name: String, kind: AccountKind, sort: Int = 0) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.sort = sort
    }
}

/// 流水（金额恒为正数，方向由 type 决定；金额一律 Decimal，PRD §5）
@Model
final class Transaction {
    @Attribute(.unique) var uid: UUID = UUID()
    var amount: Decimal
    var typeRaw: String
    var date: Date
    var note: String
    var merchant: String?
    var sourceRaw: String
    var dedupKey: String?    // 账单导入去重用（M3）
    var createdAt: Date
    var updatedAt: Date

    var category: Category?
    var account: Account?
    var toAccount: Account?  // 仅转账

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(amount: Decimal,
         type: TransactionType,
         date: Date = .now,
         note: String = "",
         merchant: String? = nil,
         source: EntrySource = .manual,
         category: Category? = nil,
         account: Account? = nil,
         toAccount: Account? = nil) {
        self.amount = amount
        self.typeRaw = type.rawValue
        self.date = date
        self.note = note
        self.merchant = merchant
        self.sourceRaw = source.rawValue
        self.dedupKey = nil
        self.createdAt = .now
        self.updatedAt = .now
        self.category = category
        self.account = account
        self.toAccount = toAccount
    }
}
