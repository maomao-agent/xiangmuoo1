import XCTest
@testable import SuishouCore

final class MoneyTests: XCTestCase {

    // MARK: - 键盘输入规则

    func testKeypadDigits() {
        XCTAssertEqual(Money.keypad("", appending: "5"), "5")
        XCTAssertEqual(Money.keypad("5", appending: "2"), "52")
        XCTAssertEqual(Money.keypad("0", appending: "7"), "7")   // 前导零替换
        XCTAssertEqual(Money.keypad("", appending: "0"), "0")
        XCTAssertEqual(Money.keypad("0", appending: "0"), "0")
    }

    func testKeypadDot() {
        XCTAssertEqual(Money.keypad("", appending: "."), "0.")
        XCTAssertEqual(Money.keypad("12", appending: "."), "12.")
        XCTAssertEqual(Money.keypad("12.", appending: "."), "12.")   // 仅一个小数点
        XCTAssertEqual(Money.keypad("12.3", appending: "5"), "12.35")
        XCTAssertEqual(Money.keypad("12.35", appending: "6"), "12.35") // 最多两位小数
    }

    func testKeypadBackspace() {
        XCTAssertEqual(Money.keypad("12.3", appending: "⌫"), "12.")
        XCTAssertEqual(Money.keypad("0.", appending: "⌫"), "0")
        XCTAssertEqual(Money.keypad("", appending: "⌫"), "")
    }

    func testKeypadIntLengthLimit() {
        let s = "123456789"
        XCTAssertEqual(Money.keypad(s, appending: "1"), s)   // 整数最多 9 位
        XCTAssertEqual(Money.keypad("0.1", appending: "2"), "0.12")
    }

    // MARK: - 解析

    func testDecimalParse() {
        XCTAssertEqual(Money.decimal(fromKeypadString: "12.35"), Decimal(string: "12.35"))
        XCTAssertEqual(Money.decimal(fromKeypadString: "0"), Decimal(0))
        XCTAssertEqual(Money.decimal(fromKeypadString: "100"), Decimal(string: "100"))
        XCTAssertNil(Money.decimal(fromKeypadString: ""))
        XCTAssertNil(Money.decimal(fromKeypadString: "."))
        XCTAssertNil(Money.decimal(fromKeypadString: "12."))
    }

    // MARK: - 格式化

    func testFormatBasic() {
        XCTAssertEqual(Money.format(Decimal(string: "12.3")!), "¥12.30")
        XCTAssertEqual(Money.format(Decimal(string: "0")!), "¥0.00")
        XCTAssertEqual(Money.format(Decimal(string: "0.05")!), "¥0.05")
        XCTAssertEqual(Money.format(Decimal(string: "8")!), "¥8.00")
    }

    func testFormatGrouping() {
        XCTAssertEqual(Money.format(Decimal(string: "1234567.891")!), "¥1,234,567.89")
        XCTAssertEqual(Money.format(Decimal(string: "1000")!, showSymbol: false), "1,000.00")
        XCTAssertEqual(Money.format(Decimal(string: "999999999")!), "¥999,999,999.00")
    }

    func testFormatNegative() {
        XCTAssertEqual(Money.format(Decimal(string: "-0.5")!), "-¥0.50")
        XCTAssertEqual(Money.format(Decimal(string: "-1234.5")!, showSymbol: false), "-1,234.50")
    }
}
