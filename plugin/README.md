# Resilient Apple Reminders TRMNL Plugin

This directory contains a TRMNL plugin recipe that displays Apple Reminders data sent by the macOS sender in the repo root.

## Files

```text
settings.yml
src/full.liquid
src/half_horizontal.liquid
src/half_vertical.liquid
src/quadrant.liquid
src/shared.liquid
samples/
```

## Data Formats

The plugin accepts all of these shapes:

### Legacy Array

```json
{
  "today": [
    {
      "name": "Install washing machine hoses",
      "deadline": "May 26, 2026 at 12:00 PM",
      "priority": "None",
      "flagged": false,
      "list": "Reminders"
    }
  ],
  "future": [],
  "overdue": []
}
```

### Legacy Singleton

This is the common Shortcuts bug. The plugin tolerates it so the screen does not render blank rows.

```json
{
  "today": {
    "name": "Install washing machine hoses",
    "deadline": "May 26, 2026 at 12:00 PM",
    "priority": "None",
    "flagged": false,
    "list": "Reminders"
  },
  "future": [],
  "overdue": []
}
```

### V2

```json
{
  "version": 2,
  "list_name": "Reminders",
  "data_time": "4:15 PM",
  "reminders": [
    {
      "idx": 1,
      "title": "Install washing machine hoses",
      "date": "Today, 12:00 PM",
      "num_tasks": 0,
      "description": "Replace the old hoses."
    }
  ]
}
```

## Validation

From the repo root:

```sh
Scripts/validate-plugin.rb
```

The validator renders all four layouts against the three sample payloads and checks that the reminder title appears without Liquid errors.
