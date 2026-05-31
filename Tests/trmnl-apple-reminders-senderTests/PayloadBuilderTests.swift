import Foundation
import Testing
@testable import TRMNLAppleRemindersCore

@Test func legacyPayloadKeepsSingleReminderBucketsAsArrays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let timeZone = TimeZone(secondsFromGMT: 0)!
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let today = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
    let reminder = ReminderItem(
        title: "Install washing machine hoses",
        dueDate: today,
        priority: 0,
        listName: "Reminders"
    )

    let payload = PayloadBuilder.buildPayload(
        reminders: [reminder],
        options: SenderOptions(listName: "Reminders", format: .legacy, now: now),
        calendar: calendar,
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: timeZone
    )
    let data = try PayloadBuilder.jsonData(from: payload)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let merge = try #require(object["merge_variables"] as? [String: Any])

    #expect(merge["today"] is [[String: Any]])
    #expect((merge["today"] as? [[String: Any]])?.count == 1)
    #expect(merge["future"] is [[String: Any]])
    #expect(merge["overdue"] is [[String: Any]])
}

@Test func v2PayloadUsesReminderArrayAndVersionTwo() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let reminder = ReminderItem(
        title: "Empty the Litter Robot",
        notes: "Poo Palace waste drawer is over 75%.",
        dueDate: now,
        listName: "Reminders",
        subtasks: 0
    )

    let payload = PayloadBuilder.buildPayload(
        reminders: [reminder],
        options: SenderOptions(listName: "Reminders", format: .v2, now: now),
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone(secondsFromGMT: 0)!
    )
    let data = try PayloadBuilder.jsonData(from: payload)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let merge = try #require(object["merge_variables"] as? [String: Any])
    let reminders = try #require(merge["reminders"] as? [[String: Any]])

    #expect(merge["version"] as? Int == 2)
    #expect(merge["list_name"] as? String == "Reminders")
    #expect(reminders.count == 1)
    #expect(reminders.first?["title"] as? String == "Empty the Litter Robot")
}

@Test func v2PayloadOmitsTimeForDateOnlyReminders() throws {
    let timeZone = TimeZone(secondsFromGMT: 0)!
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let today = calendar.startOfDay(for: now)
    let reminder = ReminderItem(
        title: "Laundry: Dryer -> Fold",
        dueDate: today,
        dueIncludesTime: false,
        listName: "Reminders"
    )

    let payload = PayloadBuilder.buildPayload(
        reminders: [reminder],
        options: SenderOptions(listName: "Reminders", format: .v2, now: now),
        calendar: calendar,
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: timeZone
    )
    let data = try PayloadBuilder.jsonData(from: payload)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let merge = try #require(object["merge_variables"] as? [String: Any])
    let reminders = try #require(merge["reminders"] as? [[String: Any]])

    #expect(reminders.first?["date"] as? String == "Today")
}

@Test func cliRejectsMissingWebhookUnlessDryRun() throws {
    #expect(throws: CLIOptionsError.missingWebhook) {
        _ = try CLIOptions(arguments: ["sender"], environment: [:])
    }

    let options = try CLIOptions(arguments: ["sender", "--dry-run"], environment: [:])
    #expect(options.dryRun)
    #expect(options.sender.listName == "Reminders")
}

@Test func sampleModeImpliesDryRunAndDoesNotNeedWebhook() throws {
    let options = try CLIOptions(arguments: ["sender", "--sample"], environment: [:])
    #expect(options.sample)
    #expect(options.dryRun)
}
