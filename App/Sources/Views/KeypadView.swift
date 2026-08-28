import SwiftUI
import SuishouCore

/// 大数字键盘：所有输入经 Money.keypad 规则校验（PRD F4）
struct KeypadView: View {
    @Binding var text: String

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            text = Money.keypad(text, appending: key)
                        } label: {
                            Text(key)
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color(.systemBackground))
    }
}
