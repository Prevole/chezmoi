#!/usr/bin/env ruby
# ---------------------------------------------------------------------------
# repos_clone — clone all repositories listed in the 1Password git repositories
# note that are missing on the filesystem.
#
# The root directory and 1Password coordinates (vault, item) are read from
# ~/.config/gitrepos/config.yaml.
#
# Supports two formats for the repositories key:
#
#   With categories (Hash):
#     repositories:
#       category1:
#         - url: git@github.com:org/foo.git        # name inferred from URL
#         - name: custom-name                       # name overrides URL basename
#           url: git@github.com:org/foo.git
#
#   Flat list (Array):
#     repositories:
#       - url: git@github.com:org/foo.git
# ---------------------------------------------------------------------------

require 'yaml'
require 'fileutils'
require_relative 'lp_1password'

# Read root from local config
local_config = YAML.load_file(File.expand_path('~/.config/gitrepos/config.yaml'))
root = File.expand_path(local_config['git']['root'])
FileUtils.mkdir_p(root)

# Read repositories from 1Password
data, _, _ = op_read_repositories
repositories = data['repositories']

cloned  = 0
skipped = 0

# Normalize to [{dir:, label:, repos:}] regardless of format
entries =
  if repositories.is_a?(Hash)
    repositories.map { |category, repos| { dir: File.join(root, category), label: category, repos: repos } }
  else
    [{ dir: root, label: nil, repos: repositories }]
  end

entries.each do |entry|
  FileUtils.mkdir_p(entry[:dir])

  entry[:repos].each do |repo|
    name   = repo['name'] || repo_name_from_url(repo['url'])
    target = File.join(entry[:dir], name)
    label  = entry[:label] ? "#{entry[:label]}/#{name}" : name

    if File.exist?(target)
      puts "skip  #{label}"
      skipped += 1
    else
      puts "clone #{label}"
      system('git', 'clone', repo['url'], target)
      cloned += 1
    end
  end
end

puts ""
puts "Done: #{cloned} cloned, #{skipped} skipped."
