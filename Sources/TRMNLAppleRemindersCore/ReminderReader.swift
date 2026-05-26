import EventKit
import Foundation

public enum ReminderReaderError: LocalizedError {
    case accessDenied
    case listNotFound(String)
    case fetchFailed

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access was denied. Grant access in System Settings > Privacy & Security > Reminders."
        case let .listNotFound(list):
            return "No Reminders list named '\(list)' was found."
        case .fetchFailed:
            return "EventKit failed to return reminders."
        }
    }
}

public final class ReminderReader: @unchecked Sendable {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func requestAccess() async throws {
        let granted: Bool

        if #available(macOS 14.0, *) {
            granted = try await store.requestFullAccessToReminders()
        } else {
            granted = try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }

        guard granted else {
            throw ReminderReaderError.accessDenied
        }
    }

    public func readIncompleteReminders(listName: String) async throws -> [ReminderItem] {
        let calendars = store.calendars(for: .reminder)
        guard let calendar = calendars.first(where: { $0.title == listName }) else {
            throw ReminderReaderError.listNotFound(listName)
        }

        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [calendar]
        )

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                guard let reminders else {
                    continuation.resume(throwing: ReminderReaderError.fetchFailed)
                    return
                }

                let items = reminders.map { reminder in
                    ReminderItem(
                        title: reminder.title ?? "",
                        notes: reminder.notes ?? "",
                        dueDate: reminder.dueDateComponents?.date,
                        priority: reminder.priority,
                        isFlagged: false,
                        listName: reminder.calendar.title,
                        subtasks: reminder.alarms?.count ?? 0
                    )
                }

                continuation.resume(returning: items)
            }
        }
    }
}
