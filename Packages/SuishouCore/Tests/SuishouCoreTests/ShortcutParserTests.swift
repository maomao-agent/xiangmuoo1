import XCTest
@testable import SuishouCore

final class ShortcutParserTests: XCTestCase {

    func testParseFullURL() {
        // note=午餐（已 percent-encode）
        let url = URL(string: "suishouzhang://add?amount=38.5&note=%E5%8D%88%E9%A4%90&type=income&date=1700000000")!
        let entry = ShortcutParser.parse(url)
        XCTAssertEqual(entry?.amount, Decimal(string: "38.5"))
        XCTAssertEqual(entry?.note, "午餐")
        XCTAssertEqual(entry?.type, "income")
        XCTAssertEqual(entry?.date, Date(timeIntervalSince1970: 1_700_000_000))
    }

    func testDefaults() {
        let url = URL(string: "suishouzhang://add?amount=12")!
        let entry = ShortcutParser.parse(url)
        XCTAssertEqual(entry?.amount, Decimal(string: "12"))
        XCTAssertEqual(entry?.note, "")
        XCTAssertEqual(entry?.type, "expense")
        XCTAssertNil(entry?.date)
    }

    func testInvalidAmountReturnsNil() {
        XCTAssertNil(ShortcutParser.parse(URL(string: "suishouzhang://add")!))                    // 缺金额
        XCTAssertNil(ShortcutParser.parse(URL(string: "suishouzhang://add?amount=0")!))          // 0 无效
        XCTAssertNil(ShortcutParser.parse(URL(string: "suishouzhang://add?amount=abc")!))        // 非数字
        XCTAssertNil(ShortcutParser.parse(URL(string: "suishouzhang://add?amount=-5")!))         // 负数无效
    }

    func testWrongSchemeOrActionReturnsNil() {
        XCTAssertNil(ShortcutParser.parse(URL(string: "https://add?amount=12")!))
        XCTAssertNil(ShortcutParser.parse(URL(string: "suishouzhang://other?amount=12")!))
    }

    func testAmountWithComma() {
        let url = URL(string: "suishouzhang://add?amount=1,234.5")!
        XCTAssertEqual(ShortcutParser.parse(url)?.amount, Decimal(string: "1234.5"))
    }

    func testUnknownTypeFallsBackToExpense() {
        let url = URL(string: "suishouzhang://add?amount=9&type=transfer")!
        XCTAssertEqual(ShortcutParser.parse(url)?.type, "expense")
    }
}
