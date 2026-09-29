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
SAMPLE_FILES = %w[legacy-array legacy-singleton v2 v2-window-mixed].freeze
EXPECTED_TITLE = "Install washing machine hoses"

# Titles that must disappear once a due window is active, and titles that must
# survive it (undated reminders, and legacy payloads that omit due_ts entirely).
WINDOW_EXCLUDED = ["Old overdue chore", "Far future project"].freeze
WINDOW_RETAINED = ["Undated someday task", "Legacy payload no due_ts"].freeze
MIXED_SAMPLE = "v2-window-mixed"

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
        "locale" => "en",
        "timestamp" => 1_800_000_000
      }
    }
  }
end

failures = []

LAYOUTS.each do |layout|
  template_path = File.join(SRC, "#{layout}.liquid")
  template = Liquid::Template.parse(expanded_markup(File.read(template_path)))

  SAMPLE_FILES.each do |sample|
    payload = JSON.parse(File.read(File.join(SAMPLES, "#{sample}.json")))

    rendered_all = template.render!(trmnl_context(window_mode: "all").merge(payload))
    unless rendered_all.include?(EXPECTED_TITLE)
      failures << "#{layout} did not render expected title for #{sample} (due_window=all)"
    end
    if rendered_all.include?("Liquid error")
      failures << "#{layout} produced a Liquid error for #{sample} (due_window=all)"
    end

    rendered_week = template.render!(trmnl_context(window_mode: "week").merge(payload))
    unless rendered_week.include?(EXPECTED_TITLE)
      failures << "#{layout} dropped expected title for #{sample} under due_window=week"
    end
    if rendered_week.include?("Liquid error")
      failures << "#{layout} produced a Liquid error for #{sample} (due_window=week)"
    end

    next unless sample == MIXED_SAMPLE

    WINDOW_EXCLUDED.each do |title|
      if rendered_week.include?(title)
        failures << "#{layout} leaked out-of-window '#{title}' under due_window=week"
      end
      unless rendered_all.include?(title)
        failures << "#{layout} lost '#{title}' under due_window=all"
      end
    end

    WINDOW_RETAINED.each do |title|
      unless rendered_week.include?(title)
        failures << "#{layout} dropped '#{title}' under due_window=week"
      end
    end
  rescue StandardError => e
    failures << "#{layout} failed for #{sample}: #{e.class}: #{e.message}"
  end
end

if failures.any?
  warn failures.join("\n")
  exit 1
end

combos = LAYOUTS.length * SAMPLE_FILES.length * 2
puts "ok plugin layouts rendered #{combos} sample combinations (due_window all + week)"
