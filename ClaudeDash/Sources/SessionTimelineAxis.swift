import Foundation

struct SessionTimelineTick: Identifiable, Equatable {
    let hourOffset: Int
    let date: Date

    var id: Int { hourOffset }

    var label: String {
        "\(hourOffset):00"
    }
}

enum SessionTimelineAxis {
    static func ticks(
        for range: (start: Date, end: Date)?,
        stepHours: Int = 4,
        calendar: Calendar = .current
    ) -> [SessionTimelineTick] {
        guard let range, stepHours > 0 else { return [] }

        let duration = max(range.end.timeIntervalSince(range.start), 0)
        let totalHours = Int(duration / 3600)

        return stride(from: 0, through: totalHours, by: stepHours).compactMap { hourOffset in
            guard let date = calendar.date(byAdding: .hour, value: hourOffset, to: range.start) else {
                return nil
            }
            return SessionTimelineTick(hourOffset: hourOffset, date: date)
        }
    }
}
