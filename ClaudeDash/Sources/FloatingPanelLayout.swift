import CoreGraphics

enum FloatingPanelLayout {
    static let panelWidth: CGFloat = 340
    static let horizontalPadding: CGFloat = 14
    static let verticalPadding: CGFloat = 14
    static let rowHeight: CGFloat = 24
    static let rowSpacing: CGFloat = 6
    static let maxVisibleSessions = 4

    static func visibleSessionCount(forTotalSessionCount totalCount: Int) -> Int {
        min(max(totalCount, 1), maxVisibleSessions)
    }

    static func panelHeight(forTotalSessionCount totalCount: Int) -> CGFloat {
        let rows = CGFloat(visibleSessionCount(forTotalSessionCount: totalCount))
        let spacing = CGFloat(max(Int(rows) - 1, 0)) * rowSpacing
        return (verticalPadding * 2) + (rows * rowHeight) + spacing
    }
}
