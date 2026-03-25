import SwiftUI

private enum SettingsPanelStyle {
    static let windowWidth: CGFloat = 520
    static let cardSpacing: CGFloat = 10
    static let sizeGridColumns = [
        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: cardSpacing),
        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: cardSpacing),
        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: cardSpacing),
    ]

    static var titleFont: Font {
        .system(size: 18, weight: .semibold)
    }

    static var cardTitleFont: Font {
        .system(size: 13, weight: .semibold, design: .rounded)
    }

    static var metaFont: Font {
        .system(size: 11, weight: .medium, design: .rounded)
    }
}

struct SettingsView: View {
    let isFirstLaunchSetup: Bool
    let onFinishSetup: (() -> Void)?

    @AppStorage(
        FloatingMascotPreferences.enabledUserDefaultsKey,
        store: ClaudeDashDefaults.shared
    ) private var isMascotEnabled = false
    @AppStorage(
        FloatingMascotSizeOption.userDefaultsKey,
        store: ClaudeDashDefaults.shared
    ) private var mascotSizeRawValue = FloatingMascotSizeOption.medium.rawValue
    @AppStorage(
        FloatingMascotAnimationSpeedOption.userDefaultsKey,
        store: ClaudeDashDefaults.shared
    ) private var mascotAnimationSpeedRawValue = FloatingMascotAnimationSpeedOption.normal.rawValue
    @AppStorage(
        FloatingMascotPreferences.didCompleteSetupUserDefaultsKey,
        store: ClaudeDashDefaults.shared
    ) private var didCompleteSetup = false

    init(
        isFirstLaunchSetup: Bool = false,
        onFinishSetup: (() -> Void)? = nil
    ) {
        self.isFirstLaunchSetup = isFirstLaunchSetup
        self.onFinishSetup = onFinishSetup
    }

    private var selectedMascotSize: FloatingMascotSizeOption {
        FloatingMascotSizeOption(rawValue: mascotSizeRawValue) ?? .medium
    }

    private var selectedAnimationSpeed: FloatingMascotAnimationSpeedOption {
        FloatingMascotAnimationSpeedOption(rawValue: mascotAnimationSpeedRawValue) ?? .normal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $isMascotEnabled) {
                    Text("悬浮精灵")
                        .font(.system(size: 13, weight: .semibold))
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.035))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.6)
                        }
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: SettingsPanelStyle.sizeGridColumns, spacing: SettingsPanelStyle.cardSpacing) {
                    ForEach(FloatingMascotSizeOption.allCases) { option in
                        FloatingMascotSizeCard(
                            option: option,
                            isSelected: option == selectedMascotSize
                        ) {
                            mascotSizeRawValue = option.rawValue
                            NotificationCenter.default.post(name: .floatingMascotSizeDidChange, object: nil)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(FloatingMascotAnimationSpeedOption.allCases) { option in
                        Button {
                            mascotAnimationSpeedRawValue = option.rawValue
                        } label: {
                            VStack(spacing: 3) {
                                Text(option.title)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(String(format: "%.2fx", option.multiplier))
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(option == selectedAnimationSpeed ? Color.accentColor.opacity(0.12) : Color.white.opacity(0.03))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                option == selectedAnimationSpeed ? Color.accentColor.opacity(0.28) : Color.white.opacity(0.06),
                                                lineWidth: option == selectedAnimationSpeed ? 0.9 : 0.6
                                            )
                                    }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if isFirstLaunchSetup {
                HStack(spacing: 10) {
                    Button("完成") {
                        didCompleteSetup = true
                        onFinishSetup?()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("稍后") {
                        onFinishSetup?()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(width: SettingsPanelStyle.windowWidth)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: isMascotEnabled) {
            didCompleteSetup = true
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("精灵")
                    .font(SettingsPanelStyle.titleFont)

                if isFirstLaunchSetup {
                    Text("先选开关和大小")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(isMascotEnabled ? "已开启" : "已关闭")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Text("\(Int(selectedMascotSize.mascotLength))pt · \(selectedAnimationSpeed.title)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
        }
    }
}

private struct FloatingMascotSizeCard: View {
    let option: FloatingMascotSizeOption
    let isSelected: Bool
    let action: () -> Void

    private var previewHeight: CGFloat {
        max(124, option.mascotLength + 34)
    }

    private var shadowWidth: CGFloat {
        max(54, option.mascotLength * 0.7)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(isSelected ? 0.06 : 0.03))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    isSelected ? Color.accentColor.opacity(0.35) : Color.white.opacity(0.06),
                                    lineWidth: isSelected ? 1.0 : 0.6
                                )
                        }

                    ZStack {
                        Ellipse()
                            .fill(Color.black.opacity(0.06))
                            .frame(width: shadowWidth, height: 12)
                            .blur(radius: 9)
                            .offset(y: 28)

                        Circle()
                            .fill(Color.claudePurple.opacity(isSelected ? 0.12 : 0.08))
                            .frame(width: 44, height: 44)
                            .blur(radius: 16)
                            .offset(y: 8)

                        FloatingMascotLottieView(playbackState: .stoppedAtFirstFrame)
                            .frame(width: option.mascotLength, height: option.mascotLength)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 10)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(10)
                    }
                }
                .frame(height: previewHeight)

                HStack(spacing: 6) {
                    Text(option.title)
                        .font(SettingsPanelStyle.cardTitleFont)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    Text("\(Int(option.mascotLength))pt")
                        .font(SettingsPanelStyle.metaFont)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
}
