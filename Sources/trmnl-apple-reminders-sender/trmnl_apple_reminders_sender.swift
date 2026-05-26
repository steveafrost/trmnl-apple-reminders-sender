import Foundation
import TRMNLAppleRemindersCore

@main
struct TRMNLAppleRemindersSender {
    static func main() async {
        do {
            let options = try CLIOptions(arguments: CommandLine.arguments)
            let reminders: [ReminderItem]

            if options.sample {
                reminders = sampleReminders(listName: options.sender.listName)
            } else {
                let reader = ReminderReader()
                try await reader.requestAccess()
                reminders = try await reader.readIncompleteReminders(listName: options.sender.listName)
            }

            let payload = PayloadBuilder.buildPayload(reminders: reminders, options: options.sender)
            let json = try jsonData(payload, pretty: options.pretty)

            if options.dryRun {
                print(String(data: json, encoding: .utf8) ?? "")
                return
            }

            guard let webhookURL = options.webhookURL else {
                throw CLIOptionsError.missingWebhook
            }

            let response = try await HTTPClient().postJSON(json, to: webhookURL)
            print(response)
        } catch is HelpRequested {
            print(usage)
        } catch {
            fputs("error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func jsonData(_ payload: [String: Any], pretty: Bool) throws -> Data {
        if pretty {
            return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        }

        return try PayloadBuilder.jsonData(from: payload)
    }

    private static func sampleReminders(listName: String) -> [ReminderItem] {
        let now = Date()
        return [
            ReminderItem(
                title: "Install washing machine hoses",
                notes: "Replace old hoses before the next laundry run.",
                dueDate: now,
                priority: 0,
                listName: listName
            )
        ]
    }
}
