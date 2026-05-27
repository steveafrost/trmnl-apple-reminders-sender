# TRMNL Recipe Submission Packet

## Recommended Submission Type

Submit this as a **Recipe**, not a Third Party plugin.

Reason: the TRMNL-side component is Liquid markup fed by a webhook. It does not require TRMNL OAuth or a hosted service that stores user data. Users run the macOS sender locally and paste their Recipe webhook URL into their own environment.

Relevant TRMNL docs:

- Recipe publishing: https://help.usetrmnl.com/en/articles/10122094-plugin-recipes
- Custom plugin types: https://help.trmnl.com/en/articles/10546870-compare-custom-plugin-types
- Plugin marketplace overview: https://docs.trmnl.com/go/plugin-marketplace/introduction

## Plugin Name

Resilient Apple Reminders

## Short Description

Display Apple Reminders on TRMNL without relying on brittle Apple Shortcuts JSON serialization.

## Longer Description

Resilient Apple Reminders is a TRMNL Recipe plus a small open-source macOS sender. The sender reads Apple Reminders locally using EventKit and posts stable JSON to the Recipe webhook. The Recipe renders older `overdue` / `today` / `future` payloads, the common Shortcuts singleton-object failure mode, and newer `v2` `reminders` payloads.

This avoids the bug where Apple Shortcuts collapses a one-item list into a single object, causing TRMNL Liquid templates to render blank reminders.

## Public Repo

https://github.com/steveafrost/trmnl-apple-reminders-sender

## Files To Copy Into TRMNL Private Plugin

```text
plugin/settings.yml
plugin/icon.svg
plugin/src/shared.liquid
plugin/src/full.liquid
plugin/src/half_horizontal.liquid
plugin/src/half_vertical.liquid
plugin/src/quadrant.liquid
```

## Test Payloads

Use these bundled sample payloads while testing the private plugin preview:

```text
plugin/samples/legacy-array.json
plugin/samples/legacy-singleton.json
plugin/samples/v2.json
```

## Local Validation

```sh
swift test
Scripts/validate-plugin.rb
```

Current status:

- Swift tests pass.
- Plugin YAML parses.
- Liquid layouts render 12 combinations: 4 layouts x 3 sample payload shapes.
- GitHub Actions CI passes.

## Recipe Publishing Steps

1. Sign in to TRMNL.
2. Create a Private Plugin / Recipe candidate.
3. Configure strategy as `webhook`.
4. Copy the files from `plugin/settings.yml` and `plugin/src/*.liquid` into the matching TRMNL fields.
5. Save the plugin.
6. Use the generated webhook URL as `TRMNL_WEBHOOK_URL` for the sender.
7. Run the sender once with `--format legacy`.
8. Confirm the preview shows a real reminder.
9. From the private plugin settings page, click the icon beside **Publish plugin?**.
10. Submit as a public Recipe, or choose Unlisted first if you want a share link before public review.

## Why This Should Be Public

Apple Reminders is a common TRMNL use case, but the existing Shortcuts-based approach can silently break when Shortcuts serializes one-item arrays as singleton objects. This Recipe gives users a more reliable path while keeping their reminder data local to their Mac and their own TRMNL webhook.

## How TRMNL Can Test

1. Install the Recipe.
2. Copy the generated webhook URL.
3. Clone the repo on macOS.
4. Build the sender:

   ```sh
   swift build -c release
   ```

5. Run with sample data first:

   ```sh
   .build/release/trmnl-apple-reminders-sender --sample --format legacy --pretty
   ```

6. Run against a real Reminders list:

   ```sh
   TRMNL_WEBHOOK_URL="..." .build/release/trmnl-apple-reminders-sender --list Reminders --format legacy
   ```

7. Confirm the Recipe preview shows the reminder title.

## Notes For Reviewers

- The Recipe itself does not collect credentials.
- The sender runs locally on the user's Mac.
- Reminder data is posted directly from the user's Mac to their TRMNL custom plugin webhook.
- The sender supports both `legacy` and `v2` payloads, but this Recipe is optimized for `legacy`.
