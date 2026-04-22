#!/usr/bin/env ruby
# ---------------------------------------------------------------------------
# repos_track_import — replace the 1Password git repositories note with the
# contents of a local YAML file.
#
# The vault and item name are read from ~/.config/gitrepos/config.yaml.
#
# Usage: repos_track_import.rb <file>
#   file — path to a YAML file with a 'repositories' key (flat list or map)
# ---------------------------------------------------------------------------

require_relative 'lp_1password'

file = ARGV[0]

if file.nil?
  warn "Usage: repos_track_import.rb <file>"
  exit 1
end

unless File.exist?(file)
  warn "File not found: #{file}"
  exit 1
end

data = YAML.safe_load(File.read(file))

unless data.is_a?(Hash) && data.key?('repositories')
  warn "Invalid format: expected a YAML file with a 'repositories' key."
  exit 1
end

repositories = data['repositories']

unless repositories.is_a?(Hash) || repositories.is_a?(Array)
  warn "Invalid format: 'repositories' must be a list (flat) or a map (categorized)."
  exit 1
end

_, vault, item = op_read_repositories

op_write_repositories(data, vault, item)

if repositories.is_a?(Hash)
  total = repositories.values.sum(&:length)
  puts "Imported #{total} repositories across #{repositories.keys.length} categories into '#{item}' (vault: #{vault})."
else
  puts "Imported #{repositories.length} repositories into '#{item}' (vault: #{vault})."
end
