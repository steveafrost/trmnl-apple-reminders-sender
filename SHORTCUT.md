# Pushing Reminders from iPhone via TRMNL Companion

Feeds plugin **315885 (Resilient Apple Reminders)** from the iPhone, no Mac required.
Companion's **Send Data to Plugin** action posts JSON to the instance's webhook with the
payload nested under a key (default `data`) — the recipe now normalizes both that shape
and the macOS sender's top-level shape, so whichever device posts last wins, safely.

## One-time setup

1. Install **TRMNL Companion** (App Store), sign in with the TRMNL account.
2. In the app: Plugins tab → pull to refresh → confirm **Resilient Apple Reminders** is listed.

## Build the Shortcut

1. Shortcuts → **+** → name it **Reminders → TRMNL**.
2. **Find Reminders** where: List is `Family`, Is not completed. Limit 25.
3. Before the loop: **Clear Variable** → new variable `rows`.
4. **Repeat with Each** item in Reminders:
   - **Format Date** of Repeat Item's Due Date → format **Unix Timestamp**
     (Format Date → Custom → Unix Timestamp). Store in nothing; used next step.
   - **Dictionary** action with keys:
     | key | value |
     | --- | --- |
     | `idx` | Repeat Index |
     | `title` | Name |
     | `date` | Format Date (Due Date, `MMM d, yyyy h:mm a`) — or Text `Today` if same day |
     | `description` | Notes |
     | `due_ts` | the Unix Timestamp number |
   - **Add to Variable** → `rows`.
5. End Repeat.
6. **Dictionary** action with keys:
   | key | value |
   | --- | --- |
   | `version` | `2` (Number) |
   | `list_name` | `Family` |
   | `data_time` | Format Date (Current Date, `h:mm a`) |
   | `reminders` | `rows` |
7. **Send Data to Plugin** (search "TRMNL"):
   - Plugin: **Resilient Apple Reminders**
   - JSON Data: the Dictionary from step 6
   - Key: `data` (the default — leave it)
8. Tap ▶ to test.

Using Dictionary actions (not hand-built Text) means Shortcuts escapes titles/notes with
quotes or emoji automatically and keeps `idx`/`due_ts` as real numbers.

## Automate it

Shortcuts → Automation → **Time of Day** (e.g. 7 AM, 1 PM, 7 PM — one automation per
time) → Run **Reminders → TRMNL**, "Run Immediately" on, "Notify When Run" off.

The payload is a full replace of the plugin's webhook data — it simply becomes the new
screen content. The macOS sender on mr-chips may keep posting too; last writer wins and
both shapes render.

## Verify

- After a test run: trmnl.com → instance → **Edit Markup** → "Your Variables" should show
  `data.reminders` with your rows.
- The device shows them on its next refresh. Rows are subject to the instance's
  **Due Window** setting (`week` hides anything beyond ±7 days; undated always show).

## Troubleshooting

- **Send Data fails / no plugin listed**: pull-to-refresh the Plugins tab in Companion;
  the action only lists webhook-strategy private plugins on the signed-in account.
- **Screen shows old data**: check the instance webhook's stored payload (Edit Markup →
  Your Variables). If `data.reminders` is stale, the automation didn't run — check the
  Shortcuts automation log.
- **Rows missing on screen but present in variables**: Due Window is filtering them —
  widen it or post a `due_ts` inside the window. Undated rows always render.
