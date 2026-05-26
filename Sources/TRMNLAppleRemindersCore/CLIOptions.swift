import Foundation

public enum CLIOptionsError: LocalizedError, Equatable {
    case missingValue(String)
    case unknownOption(String)
    case invalidFormat(String)
    case missingWebhook

    public var errorDescription: String? {
        switch self {
        case let .missingValue(option):
            return "Missing value for \(option)."
        case let .unknownOption(option):
            return "Unknown option: \(option)."
        case let .invalidFormat(format):
            return "Invalid format '\(format)'. Use 'legacy' or 'v2'."
        case .missingWebhook:
            return "Missing webhook URL. Pass --webhook or set TRMNL_WEBHOOK_URL."
        }
    }
}

public struct CLIOptions: Sendable {
    public var sender: SenderOptions
    public var webhookURL: URL?
    public var dryRun: Bool
    public var pretty: Bool
    public var sample: Bool

    public init(arguments: [String], environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        var listName = "Reminders"
        var format = PayloadFormat.legacy
        var includeUndated = false
        var futureLimit = 8
        var webhook = environment["TRMNL_WEBHOOK_URL"]
        var dryRun = false
        var pretty = false
        var sample = false

        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--list":
                guard let value = iterator.next() else { throw CLIOptionsError.missingValue(argument) }
                listName = value
            case "--format":
                guard let value = iterator.next() else { throw CLIOptionsError.missingValue(argument) }
                guard let parsed = PayloadFormat(rawValue: value) else { throw CLIOptionsError.invalidFormat(value) }
                format = parsed
            case "--webhook":
                guard let value = iterator.next() else { throw CLIOptionsError.missingValue(argument) }
                webhook = value
            case "--future-limit":
                guard let value = iterator.next() else { throw CLIOptionsError.missingValue(argument) }
                futureLimit = Int(value) ?? futureLimit
            case "--include-undated":
                includeUndated = true
            case "--dry-run":
                dryRun = true
            case "--sample":
                sample = true
                dryRun = true
            case "--pretty":
                pretty = true
            case "--help", "-h":
                dryRun = true
                pretty = true
                throw HelpRequested()
            default:
                throw CLIOptionsError.unknownOption(argument)
            }
        }

        let url = webhook.flatMap(URL.init(string:))
        if !dryRun, url == nil {
            throw CLIOptionsError.missingWebhook
        }

        self.sender = SenderOptions(
            listName: listName,
            format: format,
            includeUndated: includeUndated,
            futureLimit: futureLimit
        )
        self.webhookURL = url
        self.dryRun = dryRun
        self.pretty = pretty
        self.sample = sample
    }
}

public struct HelpRequested: Error, Sendable {}

public let usage = """
Usage:
  trmnl-apple-reminders-sender --webhook URL [options]

Options:
  --list NAME             Reminders list to read. Default: Reminders
  --format legacy|v2      TRMNL payload shape. Default: legacy
  --future-limit N        Max future reminders in legacy mode. Default: 8
  --include-undated       Include reminders without due dates in legacy future bucket
  --sample                Use sample reminder data and print JSON
  --dry-run               Print JSON instead of posting to TRMNL
  --pretty                Pretty-print JSON for dry runs

Environment:
  TRMNL_WEBHOOK_URL       Webhook URL used when --webhook is omitted
"""
