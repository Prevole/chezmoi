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
#
# name is omitted from the stored entry when it matches the URL basename,
# since repos_clone will infer it automatically in that case.
# ---------------------------------------------------------------------------

require_relative 'lp_1password'

category, name, url = ARGV

if name.nil? || url.nil?
  warn "Usage: repo_track.rb <category> <name> <url>"
  exit 1
end

data, vault, item = op_read_repositories
repositories = data['repositories']

# Build the entry — omit name if it matches the URL basename (redundant)
entry = if name == repo_name_from_url(url)
  { 'url' => url }
else
  { 'name' => name, 'url' => url }
end

# ---------------------------------------------------------------------------
# Check for duplicate and add entry
# ---------------------------------------------------------------------------
if repositories.is_a?(Hash)
  cat = category.nil? || category.empty? ? '_uncategorized' : category
  existing = (repositories[cat] || []).any? { |r| (r['name'] || repo_name_from_url(r['url'])) == name }
  if existing
    puts "Already tracked: #{cat}/#{name}"
    exit 0
  end
  repositories[cat] ||= []
  repositories[cat] << entry
  label = "#{cat}/#{name}"
else
  existing = repositories.any? { |r| (r['name'] || repo_name_from_url(r['url'])) == name }
  if existing
    puts "Already tracked: #{name}"
    exit 0
  end
  repositories << entry
  label = name
end

# ---------------------------------------------------------------------------
# Write updated repositories back to 1Password
# ---------------------------------------------------------------------------
op_write_repositories(data, vault, item)

puts "Tracked: #{label} (#{url})"
