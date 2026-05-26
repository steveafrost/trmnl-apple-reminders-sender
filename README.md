# TRMNL Apple Reminders Sender

A small native macOS sender for syncing Apple Reminders to a TRMNL custom plugin without relying on Apple Shortcuts as the data engine.

The main bug this avoids: Shortcuts can collapse a one-item list into a single object. TRMNL Liquid templates usually expect arrays, so one reminder can render as blank rows or broken Liquid. This sender always emits stable JSON arrays.

## Supported TRMNL Payloads

### `legacy`

Use this for older Apple Reminders plugins that expect three buckets:

```json
{
  "merge_variables": {
    "overdue": [],
    "today": [
      {
        "name": "Install washing machine hoses",
        "deadline": "May 26, 2026 at 4:05 PM",
        "priority": "None",
        "flagged": false,
        "list": "Reminders"
      }
    ],
    "future": []
  }
}
```

### `v2`

Use this for newer TRMNL recipes that expect `version: 2` and a `reminders` array:

```json
{
  "merge_variables": {
    "version": 2,
    "list_name": "Reminders",
    "data_time": "4:05 PM",
    "reminders": [
      {
        "idx": 1,
        "title": "Install washing machine hoses",
        "date": "Today, 4:05 PM",
        "num_tasks": 0,
        "description": ""
      }
    ]
  }
}
```

## Build

```sh
swift build -c release
```

The executable will be at:

```sh
.build/release/trmnl-apple-reminders-sender
```

## Usage

Dry-run with sample data:

```sh
swift run trmnl-apple-reminders-sender --sample --format legacy --pretty
swift run trmnl-apple-reminders-sender --sample --format v2 --pretty
```

Dry-run against a real Reminders list:

```sh
swift run trmnl-apple-reminders-sender --list Reminders --format legacy --dry-run --pretty
```

Post to TRMNL:

```sh
TRMNL_WEBHOOK_URL="https://usetrmnl.com/api/custom_plugins/YOUR-PLUGIN-UUID" \
  .build/release/trmnl-apple-reminders-sender --list Reminders --format legacy
```

Options:

```text
--list NAME             Reminders list to read. Default: Reminders
--format legacy|v2      TRMNL payload shape. Default: legacy
--future-limit N        Max future reminders in legacy mode. Default: 8
--include-undated       Include reminders without due dates in legacy future bucket
--sample                Use sample reminder data and print JSON
--dry-run               Print JSON instead of posting to TRMNL
--pretty                Pretty-print JSON for dry runs
--webhook URL           TRMNL custom plugin webhook URL
```

## macOS Permissions

The sender uses EventKit, Apple's native Reminders API. macOS must grant Reminders access to the process that runs it.

If the command prints:

```text
error: Reminders access was denied.
```

open:

```text
System Settings > Privacy & Security > Reminders
```

and grant access to the terminal app, automation runner, or service wrapper that launches the sender.

For unattended use, run the sender from one stable path. Rebuilding into new temporary paths can cause macOS to treat the executable as a different privacy identity.

## Node-RED Integration

The reliable pattern is:

1. Node-RED runs on a timer.
2. Node-RED calls a stable local Mac endpoint or script runner.
3. That runner executes this binary.
4. This binary reads Reminders and posts directly to TRMNL.

Avoid using Node-RED to trigger an Apple Shortcut for the sync. That reintroduces Shortcuts serialization, iCloud sync, and duplicate-name ambiguity.

Example Node-RED HTTP payload for a local relay:

```json
{
  "trmnlReminders": {
    "list": "Reminders",
    "format": "legacy"
  }
}
```

## Tests

```sh
swift test
```

The test suite includes the regression that matters most for the current TRMNL failure: a single reminder in `today` remains encoded as `today: [ ... ]`, not `today: { ... }`.
