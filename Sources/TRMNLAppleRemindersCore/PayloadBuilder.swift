import Foundation

public enum PayloadBuilder {
    public static func buildPayload(
        reminders: [ReminderItem],
        options: SenderOptions,
        calendar: Calendar = .current,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> [String: Any] {
        let mergeVariables: [String: Any]

        switch options.format {
        case .legacy:
            mergeVariables = buildLegacyMergeVariables(
                reminders: reminders,
                options: options,
                calendar: calendar,
                locale: locale,
                timeZone: timeZone
            )
        case .v2:
            mergeVariables = buildV2MergeVariables(
                reminders: reminders,
                options: options,
                calendar: calendar,
                locale: locale,
                timeZone: timeZone
            )
        }

        return ["merge_variables": mergeVariables]
    }

    public static func jsonData(from payload: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    }

    private static func buildLegacyMergeVariables(
        reminders: [ReminderItem],
        options: SenderOptions,
        calendar: Calendar,
        locale: Locale,
        timeZone: TimeZone
    ) -> [String: Any] {
        let startOfToday = calendar.startOfDay(for: options.now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        var overdue: [[String: Any]] = []
        var today: [[String: Any]] = []
        var future: [[String: Any]] = []

        for reminder in sort(reminders) {
            guard let dueDate = reminder.dueDate else {
                if options.includeUndated {
                    future.append(legacyReminder(reminder, locale: locale, timeZone: timeZone))
                }
                continue
            }

            let encoded = legacyReminder(reminder, locale: locale, timeZone: timeZone)
            if dueDate < startOfToday {
                overdue.append(encoded)
            } else if dueDate < startOfTomorrow {
                today.append(encoded)
            } else {
                future.append(encoded)
            }
        }

        if options.futureLimit > 0 {
            future = Array(future.prefix(options.futureLimit))
        }

        return [
            "overdue": overdue,
            "today": today,
            "future": future
        ]
    }

    private static func buildV2MergeVariables(
        reminders: [ReminderItem],
        options: SenderOptions,
        calendar: Calendar,
        locale: Locale,
        timeZone: TimeZone
    ) -> [String: Any] {
        let visible = sort(reminders).enumerated().map { index, reminder in
            [
                "idx": index + 1,
                "title": reminder.title,
                "date": reminder.dueDate.map {
                    relativeDateString(
                        $0,
                        includesTime: reminder.dueIncludesTime,
                        now: options.now,
                        calendar: calendar,
                        locale: locale,
                        timeZone: timeZone
                    )
                } ?? "",
                "num_tasks": reminder.subtasks,
                "description": reminder.notes
            ] as [String: Any]
        }

        return [
            "version": 2,
            "list_name": options.listName,
            "data_time": timeString(options.now, locale: locale, timeZone: timeZone),
            "reminders": visible
        ]
    }

    private static func legacyReminder(
        _ reminder: ReminderItem,
        locale: Locale,
        timeZone: TimeZone
    ) -> [String: Any] {
        [
            "name": reminder.title,
            "deadline": reminder.dueDate.map {
                fullDateString($0, includesTime: reminder.dueIncludesTime, locale: locale, timeZone: timeZone)
            } ?? "",
            "priority": priorityString(reminder.priority),
            "flagged": reminder.isFlagged,
            "list": reminder.listName
        ]
    }

    private static func sort(_ reminders: [ReminderItem]) -> [ReminderItem] {
        reminders.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l == r { return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending }
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    private static func priorityString(_ priority: Int) -> String {
        switch priority {
        case 1...3:
            return "High"
        case 4...6:
            return "Medium"
        case 7...9:
            return "Low"
        default:
            return "None"
        }
    }

    private static func fullDateString(
        _ date: Date,
        includesTime: Bool,
        locale: Locale,
        timeZone: TimeZone
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = includesTime ? .short : .none
        return formatter.string(from: date)
    }

    private static func timeString(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func relativeDateString(
        _ date: Date,
        includesTime: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale,
        timeZone: TimeZone
    ) -> String {
        var calendar = calendar
        calendar.timeZone = timeZone

        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "Today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(date, inSameDayAs: tomorrow) {
            day = "Tomorrow"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            day = "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = timeZone
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            day = formatter.string(from: date)
        }

        guard includesTime else {
            return day
        }

        return "\(day), \(timeString(date, locale: locale, timeZone: timeZone))"
    }
}
