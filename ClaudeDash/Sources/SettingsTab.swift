// SettingsTab.swift
// ClaudeDash - 设置窗口
// Liquid Glass 风格：玻璃卡片 + 渐变 accent

import SwiftUI

struct SettingsTab: View {
    // MARK: - 设置项（UserDefaults 持久化）

    @AppStorage("ClaudeDash_minDuration") private var minDuration: Double = 15
    @AppStorage("ClaudeDash_notificationTemplate") private var notificationTemplate: String = "{project} 已完成 - 耗时 {duration}，费用 {cost}"
    @AppStorage("ClaudeDash_notificationSound") private var notificationSound: String = "Glass"
    @AppStorage("ClaudeDash_enableSummary") private var enableSummary: Bool = true
    @AppStorage("ClaudeDash_longTaskOnly") private var longTaskOnly: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 标题
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ClaudeGradients.primary)
                    Text("Settings")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // 最小触发时长
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label {
                            Text("最小触发时长")
                                .font(.system(size: 13, weight: .semibold))
                        } icon: {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.claudePurple)
                        }
                        Spacer()
                        Text("\(Int(minDuration))s")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.claudePurple)
                    }

                    Slider(value: $minDuration, in: 0...120, step: 5) {
                        Text("时长")
                    } minimumValueLabel: {
                        Text("0s").font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
                    } maximumValueLabel: {
                        Text("120s").font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
                    }
                    .tint(Color.claudePurple)

                    Text("低于此时长的任务将不会触发通知")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 24)

                // 通知模板
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("通知模板")
                            .font(.system(size: 13, weight: .semibold))
                    } icon: {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.claudeCyan)
                    }

                    TextField("通知内容模板", text: $notificationTemplate)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(10)
                        .glassBackground(cornerRadius: 10)

                    HStack(spacing: 6) {
                        ForEach(["{project}", "{duration}", "{cost}", "{summary}"], id: \.self) { variable in
                            Button {
                                notificationTemplate += " " + variable
                            } label: {
                                Text(variable)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .glassBackground(cornerRadius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("支持变量：{project} 项目名、{duration} 耗时、{cost} 费用、{summary} 摘要")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 24)

                // 声音选择
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("通知声音")
                            .font(.system(size: 13, weight: .semibold))
                    } icon: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }

                    HStack(spacing: 4) {
                        ForEach(NotificationSound.allCases, id: \.rawValue) { sound in
                            Button {
                                notificationSound = sound.rawValue
                            } label: {
                                Text(sound.rawValue)
                                    .font(.system(size: 11, weight: notificationSound == sound.rawValue ? .semibold : .medium))
                                    .foregroundStyle(notificationSound == sound.rawValue ? .primary : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        if notificationSound == sound.rawValue {
                                            Capsule()
                                                .fill(Color.claudePurple.opacity(0.15))
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .glassBackground(cornerRadius: 14)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 24)

                // 开关选项
                VStack(spacing: 14) {
                    settingsToggle(
                        isOn: $enableSummary,
                        icon: "text.magnifyingglass",
                        iconColor: .green,
                        title: "智能总结",
                        description: "在通知副标题中显示任务完成摘要"
                    )

                    settingsToggle(
                        isOn: $longTaskOnly,
                        icon: "hourglass",
                        iconColor: .blue,
                        title: "仅长任务",
                        description: "仅超过最小触发时长的任务才会触发通知"
                    )
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 24)

                // 版本信息
                HStack {
                    Spacer()
                    Text("ClaudeDash v1.0.0")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.quaternary)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - 开关行

    private func settingsToggle(
        isOn: Binding<Bool>,
        icon: String,
        iconColor: Color,
        title: String,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: isOn) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(iconColor)
                        .frame(width: 16)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
            }
            .toggleStyle(.switch)
            .tint(Color.claudePurple)

            Text(description)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.leading, 24)
        }
    }
}

#Preview {
    SettingsTab()
        .frame(width: 520, height: 500)
}
