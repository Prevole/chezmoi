#!/usr/bin/env ruby
# ---------------------------------------------------------------------------
# repo_track — add the current git repository to the 1Password note that
# holds the git repositories list.
#
# The vault and item name are read from ~/.config/gitrepos/config.yaml
# under the onepassword key.
#
# Usage: repo_track.rb <category> <name> <url>
#   category — category to file the repo under, or "" for flat list
#   name     — repo directory name (e.g. foo)
#   url      — git remote URL (e.g. git@github.com:org/foo.git)
# ---------------------------------------------------------------------------

require_relative 'lp_1password'

category, name, url = ARGV

if name.nil? || url.nil?
  warn "Usage: repo_track.rb <category> <name> <url>"
  exit 1
end

data, vault, item = op_read_repositories
repositories = data['repositories']

# ---------------------------------------------------------------------------
# Check for duplicate and add entry
# ---------------------------------------------------------------------------
if repositories.is_a?(Hash)
  cat = category.nil? || category.empty? ? '_uncategorized' : category
  existing = (repositories[cat] || []).any? { |r| r['name'] == name }
  if existing
    puts "Already tracked: #{cat}/#{name}"
    exit 0
  end
  repositories[cat] ||= []
  repositories[cat] << { 'name' => name, 'url' => url }
  label = "#{cat}/#{name}"
else
  existing = repositories.any? { |r| r['name'] == name }
  if existing
    puts "Already tracked: #{name}"
    exit 0
  end
  repositories << { 'name' => name, 'url' => url }
  label = name
end

# ---------------------------------------------------------------------------
# Write updated repositories back to 1Password
# ---------------------------------------------------------------------------
op_write_repositories(data, vault, item)

puts "Tracked: #{label} (#{url})"
