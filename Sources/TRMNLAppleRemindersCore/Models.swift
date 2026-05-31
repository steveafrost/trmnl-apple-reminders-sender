import Foundation

public struct ReminderItem: Equatable, Sendable {
    public var title: String
    public var notes: String
    public var dueDate: Date?
    public var dueIncludesTime: Bool
    public var priority: Int
    public var isFlagged: Bool
    public var listName: String
    public var subtasks: Int

    public init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        dueIncludesTime: Bool = true,
        priority: Int = 0,
        isFlagged: Bool = false,
        listName: String,
        subtasks: Int = 0
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.dueIncludesTime = dueIncludesTime
        self.priority = priority
        self.isFlagged = isFlagged
        self.listName = listName
        self.subtasks = subtasks
    }
}

public enum PayloadFormat: String, Sendable {
    case legacy
    case v2
}

public struct SenderOptions: Sendable {
    public var listName: String
    public var format: PayloadFormat
    public var includeUndated: Bool
    public var futureLimit: Int
    public var now: Date

    public init(
        listName: String = "Reminders",
        format: PayloadFormat = .legacy,
        includeUndated: Bool = false,
        futureLimit: Int = 8,
        now: Date = Date()
    ) {
        self.listName = listName
        self.format = format
        self.includeUndated = includeUndated
        self.futureLimit = futureLimit
        self.now = now
    }
}
