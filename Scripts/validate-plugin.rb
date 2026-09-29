#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

begin
  require "liquid"
rescue LoadError
  warn "Missing Ruby gem: liquid"
  warn "Install with: gem install --user-install liquid"
  exit 2
end

ROOT = File.expand_path("..", __dir__)
PLUGIN = File.join(ROOT, "plugin")
SRC = File.join(PLUGIN, "src")
SAMPLES = File.join(PLUGIN, "samples")
LAYOUTS = %w[full half_horizontal half_vertical quadrant].freeze
STATIC_SAMPLES = %w[legacy-array legacy-singleton v2 companion-v2].freeze
EXPECTED_TITLE = "Install washing machine hoses"

# The window anchors to the production fallback ("now" | date: "%s") because
# TRMNL injects no trmnl.user.timestamp. Window assertions therefore use a
# payload whose due_ts values are computed against real wall-clock time;
# plugin/samples/v2-window-mixed.json documents the payload shape statically.
WINDOW_EXCLUDED = ["Old overdue chore", "Far future project"].freeze
WINDOW_RETAINED = ["Undated someday task", "Legacy payload no due_ts"].freeze

SHARED = File.read(File.join(SRC, "shared.liquid"))

def expanded_markup(layout_markup)
  templates = {}
  shared_without_templates = SHARED.gsub(
    /{%\s*template\s+([A-Za-z0-9_]+)\s*%}(.*?){%\s*endtemplate\s*%}/m
  ) do
    templates[Regexp.last_match(1)] = Regexp.last_match(2)
    ""
  end

  expanded = layout_markup.gsub(/{%\s*render\s+"([A-Za-z0-9_]+)"[^%]*%}/) do
    templates.fetch(Regexp.last_match(1)) do
      raise "unknown shared template: #{Regexp.last_match(1)}"
    end
  end

  "#{shared_without_templates}\n#{expanded}"
end

def trmnl_context(window_mode:)
  {
    "trmnl" => {
      "plugin_settings" => {
        "custom_fields_values" => {
          "show_details" => "yes",
          "expected_format" => "legacy",
          "due_window" => window_mode
        }
      },
      "user" => {
        "locale" => "en"
      }
    }
  }
end

def mixed_payload
  now = Time.now.to_i
  day = 86_400
  {
    "version" => 2,
    "list_name" => "Reminders",
    "data_time" => "4:15 PM",
    "reminders" => [
      {"idx" => 1, "title" => EXPECTED_TITLE, "date" => "Today", "num_tasks" => 0,
       "description" => "Due right now.", "due_ts" => now},
      {"idx" => 2, "title" => "Old overdue chore", "date" => "Jun 1, 2026", "num_tasks" => 0,
       "description" => "Far past the window.", "due_ts" => now - 90 * day},
      {"idx" => 3, "title" => "Far future project", "date" => "Mar 27, 2030", "num_tasks" => 0,
       "description" => "Deep future.", "due_ts" => now + 120 * day},
      {"idx" => 4, "title" => "Undated someday task", "date" => "", "num_tasks" => 0,
       "description" => "No date attached.", "due_ts" => 0},
      {"idx" => 5, "title" => "Legacy payload no due_ts", "date" => "May 26, 2026", "num_tasks" => 0,
       "description" => "Old sender, missing due_ts key."}
    ]
  }
end

failures = []
checks = 0

LAYOUTS.each do |layout|
  template_path = File.join(SRC, "#{layout}.liquid")
  template = Liquid::Template.parse(expanded_markup(File.read(template_path)))

  STATIC_SAMPLES.each do |sample|
    payload = JSON.parse(File.read(File.join(SAMPLES, "#{sample}.json")))

    rendered_all = template.render!(trmnl_context(window_mode: "all").merge(payload))
    checks += 1
    unless rendered_all.include?(EXPECTED_TITLE)
      failures << "#{layout} did not render expected title for #{sample} (due_window=all)"
    end
    if rendered_all.include?("Liquid error")
      failures << "#{layout} produced a Liquid error for #{sample} (due_window=all)"
    end
    if rendered_all =~ /\{[{%#]/
      failures << "#{layout} leaked unrendered Liquid/comment syntax for #{sample} (due_window=all)"
    end

    # Week render must stay error-free; dated rows' visibility depends on the
    # sample's static epochs vs wall-clock time, so no dated-title assertion here.
    rendered_week = template.render!(trmnl_context(window_mode: "week").merge(payload))
    checks += 1
    if rendered_week.include?("Liquid error")
      failures << "#{layout} produced a Liquid error for #{sample} (due_window=week)"
    end
    if %w[v2 companion-v2].include?(sample) && !rendered_week.include?("Water the ferns")
      # undated rows must survive any window
      failures << "#{layout} dropped undated row for #{sample} under due_window=week"
    end
    if sample == "companion-v2" && !rendered_all.include?("Water the ferns")
      failures << "#{layout} dropped Companion-nested undated row under due_window=all"
    end
  rescue StandardError => e
    failures << "#{layout} failed for #{sample}: #{e.class}: #{e.message}"
  end

  payload = mixed_payload
  rendered_all = template.render!(trmnl_context(window_mode: "all").merge(payload))
  rendered_week = template.render!(trmnl_context(window_mode: "week").merge(payload))

  checks += 1
  unless rendered_all.include?(EXPECTED_TITLE)
    failures << "#{layout} lost in-window title under due_window=all"
  end
  WINDOW_EXCLUDED.each do |title|
    unless rendered_all.include?(title)
      failures << "#{layout} lost '#{title}' under due_window=all"
    end
  end

  checks += 1
  unless rendered_week.include?(EXPECTED_TITLE)
    failures << "#{layout} dropped in-window title under due_window=week"
  end
  WINDOW_EXCLUDED.each do |title|
    if rendered_week.include?(title)
      failures << "#{layout} leaked out-of-window '#{title}' under due_window=week"
    end
  end
  WINDOW_RETAINED.each do |title|
    unless rendered_week.include?(title)
      failures << "#{layout} dropped '#{title}' under due_window=week"
    end
  end
  [rendered_all, rendered_week].each_with_index do |rendered, i|
    if rendered.include?("Liquid error")
      failures << "#{layout} produced a Liquid error (mixed, #{i == 0 ? "all" : "week"})"
    end
  end
rescue StandardError => e
  failures << "#{layout} failed: #{e.class}: #{e.message}"
end

if failures.any?
  warn failures.join("\n")
  exit 1
end

puts "ok plugin layouts rendered #{checks} render combinations with window assertions"
