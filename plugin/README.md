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

## Due Window

The plugin instance exposes a `Due Window` custom field (`all`, `week`, `month`, `year`). Non-`all`
settings keep only reminders due within a rolling window of the screen render time (week = ±7 days,
month = ±31 days, year = ±365 days). Reminders without a due date always stay visible; dated
reminders outside the window are hidden.

The recipe filters on a `due_ts` (Unix epoch seconds) field per reminder. The bundled macOS sender
includes it in both payload formats; older payloads without `due_ts` simply render unfiltered.

## Validation

From the repo root:

```sh
Scripts/validate-plugin.rb
```

The validator renders all four layouts against every sample payload under both `due_window=all`
and `due_window=week`, checking that the expected reminder title renders, out-of-window titles
are filtered, undated and legacy (no `due_ts`) rows stay visible, and no Liquid errors appear.
