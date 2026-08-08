import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: MeasureViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("单位") {
                    Picker("显示单位", selection: $model.unitSettings.unit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                }

                Section("设备能力") {
                    CapabilityRow(title: "ARKit", supported: model.capabilities.arKitAvailable)
                    CapabilityRow(title: "LiDAR / SceneDepth", supported: model.capabilities.sceneDepthAvailable)
                    CapabilityRow(title: "Smoothed SceneDepth", supported: model.capabilities.smoothedSceneDepthAvailable)
                    CapabilityRow(title: "Mesh Reconstruction", supported: model.capabilities.meshReconstructionAvailable)
                    CapabilityRow(title: "RoomPlan", supported: model.capabilities.roomPlanAvailable)
                }

                Section("说明") {
                    Text("ARKit / LiDAR 是辅助测量工具。结果会受到距离、材质、光照、角度、移动、反光、透明或黑色物体影响，不承诺工业计量级精度。建议在 0.3–3 米范围内保持手机稳定。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("版本") {
                    LabeledContent("App Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            }
            .navigationTitle("设置")
        }
    }
}

private struct CapabilityRow: View {
    let title: String
    let supported: Bool

    var body: some View {
        Label(title, systemImage: supported ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(supported ? .green : .secondary)
    }
}

