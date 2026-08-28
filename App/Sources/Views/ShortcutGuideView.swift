import SwiftUI

/// 快捷指令接入指南（PRD F2）：三套模板 + URL 格式说明
struct ShortcutGuideView: View {

    private static let exampleURL = "suishouzhang://add?amount=38.5&note=午餐&type=expense"

    var body: some View {
        List {
            Section("原理") {
                Text("iOS 快捷指令负责「采集金额并唤起」，随手账负责「接收并确认」。付款后在快捷指令里输入金额，随手账会自动弹出预填好的卡片，点一下分类即完成入账。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("URL 格式") {
                monoText(Self.exampleURL)
                copyButton(Self.exampleURL)

                LabeledContent("amount", value: "必填，金额（如 38.5）")
                LabeledContent("note", value: "可选，备注")
                LabeledContent("type", value: "可选，expense（默认）/ income")
                LabeledContent("date", value: "可选，Unix 秒级时间戳")
            }

            Section("模板一：打开支付宝/微信时自动弹窗（推荐）") {
                steps([
                    "打开「快捷指令」App → 底部「自动化」→ 右上角 + 新建",
                    "选「App」→ 勾选「支付宝」→ 选「已打开」→ 运行方式选「立即运行」",
                    "添加动作「要求输入」：提示语填“刚花了多少钱”，键盘类型选「数字」",
                    "添加动作「打开 URL」：URL 填 suishouzhang://add?amount=【提供的输入】&note=支付宝",
                    "微信同理，再建一条自动化即可",
                ])
                Text("效果：每次打开支付宝付款前，会先弹出金额输入框；输完即跳随手账确认。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("模板二：控制中心 / 锁屏按钮手动触发") {
                steps([
                    "「快捷指令」→ 「快捷指令」标签 → + 新建，命名如“记一笔”",
                    "添加动作「要求输入」（数字）→ 添加动作「打开 URL」（同上格式）",
                    "设置 → 控制中心 → 把「记一笔」加入控制中心；或在快捷指令详情里「添加到主屏幕/锁定屏幕」",
                    "付款后从控制中心或锁屏一点，即可唤起",
                ])
            }

            Section("模板三：截图识别（进阶，可后续再配）") {
                steps([
                    "付款成功页截图",
                    "快捷指令：「获取最新的截图」→「从图像提取文本」→「匹配文本」用正则 ([0-9]+\\.?[0-9]{0,2}) 提取金额",
                    "「打开 URL」：suishouzhang://add?amount=【匹配的文本】",
                ])
                Text("此模板完全离线，截图不需发往任何服务器。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("注意事项") {
                Label("iOS 无法做到零操作自动记账，输入金额这一步是系统限制下的最短路径",
                      systemImage: "info.circle")
                Label("预确认卡片里可改金额、选分类、选账户，保存即入账",
                      systemImage: "checkmark.circle")
            }
        }
        .navigationTitle("快捷指令接入")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 子视图

    private func monoText(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 8))
    }

    private func copyButton(_ text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
        } label: {
            Label("复制示例 URL", systemImage: "doc.on.doc")
                .font(.subheadline)
        }
    }

    private func steps(_ items: [String]) -> some View {
        ForEach(Array(items.enumerated()), id: \.offset) { index, text in
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption2.weight(.bold))
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor.opacity(0.15), in: Circle())
                    .foregroundStyle(Color.accentColor)
                Text(text).font(.subheadline)
            }
            .padding(.vertical, 2)
        }
    }
}
