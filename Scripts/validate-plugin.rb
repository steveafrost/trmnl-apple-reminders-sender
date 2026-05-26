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
SAMPLE_FILES = %w[legacy-array legacy-singleton v2].freeze
EXPECTED_TITLE = "Install washing machine hoses"

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

def trmnl_context
  {
    "trmnl" => {
      "plugin_settings" => {
        "custom_fields_values" => {
          "show_details" => "yes",
          "expected_format" => "legacy"
        }
      },
      "user" => {
        "locale" => "en"
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
    rendered = template.render!(trmnl_context.merge(payload))

    unless rendered.include?(EXPECTED_TITLE)
      failures << "#{layout} did not render expected title for #{sample}"
    end

    if rendered.include?("Liquid error")
      failures << "#{layout} produced a Liquid error for #{sample}"
    end
  rescue StandardError => e
    failures << "#{layout} failed for #{sample}: #{e.class}: #{e.message}"
  end
end

if failures.any?
  warn failures.join("\n")
  exit 1
end

puts "ok plugin layouts rendered #{LAYOUTS.length * SAMPLE_FILES.length} sample combinations"
