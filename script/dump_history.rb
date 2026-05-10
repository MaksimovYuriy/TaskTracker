#!/usr/bin/env ruby
# frozen_string_literal: true

# Конвертирует JSONL-лог сессии Claude Code в человекочитаемый markdown.
# Использование:
#   ruby script/dump_history.rb [output_file]
# По умолчанию пишет в HISTORY_FULL.md в корне проекта.

require "json"
require "time"

DEFAULT_SESSIONS_DIRS = [
  "/mnt/c/Users/yuram/.claude/projects/--wsl-localhost-Ubuntu-home-yuriy-TaskTracker",
  File.expand_path("~/.claude/projects/--wsl-localhost-Ubuntu-home-yuriy-TaskTracker")
].freeze

SESSIONS_DIR = ENV.fetch("CLAUDE_SESSIONS_DIR") do
  DEFAULT_SESSIONS_DIRS.find { |d| Dir.exist?(d) } || DEFAULT_SESSIONS_DIRS.first
end

OUTPUT = ARGV[0] || File.expand_path("../HISTORY.md", __dir__)

session_files = Dir["#{SESSIONS_DIR}/*.jsonl"].sort_by { |f| File.mtime(f) }
abort "No JSONL session files found in #{SESSIONS_DIR}" if session_files.empty?

def strip_meta(text)
  text = text.dup
  text.gsub!(%r{<ide_opened_file>.*?</ide_opened_file>}m, "")
  text.gsub!(%r{<ide_selection>.*?</ide_selection>}m, "")
  text.gsub!(%r{<system-reminder>.*?</system-reminder>}m, "")
  text.gsub!(%r{<command-name>.*?</command-name>}m, "")
  text.strip
end

def extract_text(content)
  return strip_meta(content) if content.is_a?(String)
  return "" unless content.is_a?(Array)

  parts = content.filter_map do |block|
    next unless block.is_a?(Hash) && block["type"] == "text"

    block["text"]
  end
  strip_meta(parts.join("\n\n"))
end

turns = []
session_files.each do |path|
  File.foreach(path) do |raw|
    next if raw.strip.empty?

    obj = begin
      JSON.parse(raw)
    rescue JSON::ParserError
      next
    end

    role = obj["type"]
    next unless %w[user assistant].include?(role)

    msg = obj["message"] || {}
    text = extract_text(msg["content"])
    next if text.empty?

    turns << { role: role, timestamp: obj["timestamp"], text: text, file: File.basename(path) }
  end
end

File.open(OUTPUT, "w") do |out|
  out.puts "# Полный транскрипт диалога Task Tracker"
  out.puts
  out.puts "Источник: сессии Claude Code из `#{SESSIONS_DIR}`."
  out.puts
  out.puts "Файлов сессий: #{session_files.size}, реплик в сумме: #{turns.size}."
  out.puts
  out.puts "Из текста удалены только IDE-метаданные (`<ide_opened_file>`, `<ide_selection>`) и system-reminder'ы."
  out.puts "Tool-вызовы и tool-результаты пропущены — оставлены только реплики пользователя и ассистента."
  out.puts
  out.puts "---"
  out.puts

  turns.each do |t|
    label = t[:role] == "user" ? "👤 User" : "🤖 Assistant"
    ts = begin
      Time.parse(t[:timestamp]).strftime("%Y-%m-%d %H:%M:%S UTC")
    rescue StandardError
      "?"
    end
    out.puts "## #{label} — #{ts}"
    out.puts
    out.puts t[:text]
    out.puts
    out.puts "---"
    out.puts
  end
end

puts "Wrote #{turns.size} turns to #{OUTPUT} (#{File.size(OUTPUT)} bytes)"
