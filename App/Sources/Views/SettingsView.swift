import SwiftUI

/// 设置页（M1 精简版：分类/账户管理 + 里程碑占位说明）
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("管理") {
                    NavigationLink("分类管理", destination: CategoryManageView())
                    NavigationLink("账户管理", destination: AccountManageView())
                }

                Section("数据") {
                    LabeledContent("快捷指令接入", value: "M2 里程碑")
                    LabeledContent("账单 CSV 导入", value: "M3 里程碑")
                    LabeledContent("导出 CSV", value: "M5 里程碑")
                }

                Section("关于") {
                    LabeledContent("版本", value: "0.1.0（M1）")
                    LabeledContent("数据存储", value: "仅保存在本机")
                }
            }
            .navigationTitle("设置")
        }
    }
}
