#!/usr/bin/env ruby
# ---------------------------------------------------------------------------
# lp_1password — shared helpers for reading/writing the git repositories note
# in 1Password.
#
# The vault and item name are read from ~/.config/gitrepos/config.yaml under
# the onepassword key, so the config file is the single source of truth for
# locating the note.
# ---------------------------------------------------------------------------

require 'yaml'
require 'json'
require 'open3'

CONFIG_FILE = File.expand_path('~/.config/gitrepos/config.yaml')

def op_config
  unless File.exist?(CONFIG_FILE)
    warn "Config file not found: #{CONFIG_FILE}"
    exit 1
  end

  config = YAML.load_file(CONFIG_FILE)
  vault  = config.dig('onepassword', 'vault')
  item   = config.dig('onepassword', 'item')

  if vault.nil? || item.nil?
    warn "Missing onepassword.vault or onepassword.item in #{CONFIG_FILE}"
    exit 1
  end

  [vault, item]
end

def op_read_repositories
  vault, item = op_config
  note_ref    = "op://#{vault}/#{item}/notesPlain"

  raw, status = Open3.capture2('op', 'read', note_ref)

  unless status.success?
    warn "Failed to read '#{note_ref}' from 1Password."
    warn "Make sure the note exists: vault=#{vault}, item='#{item}', field=notesPlain"
    exit 1
  end

  [YAML.safe_load(raw), vault, item]
end

# Extract the repository name from a git URL.
# Works with SSH (git@github.com:org/repo.git) and HTTPS URLs.
def repo_name_from_url(url)
  File.basename(url, '.git')
end

def op_write_repositories(data, vault, item)  yaml_content = data.to_yaml

  # Fetch the full item JSON, update notesPlain, pipe back to op item edit
  item_json, status = Open3.capture2('op', 'item', 'get', "--vault=#{vault}", item, '--format=json')
  unless status.success?
    warn "Failed to fetch '#{item}' from 1Password vault '#{vault}'."
    exit 1
  end

  item_data = JSON.parse(item_json)
  notes_field = item_data['fields'].find { |f| f['id'] == 'notesPlain' }
  if notes_field.nil?
    warn "Field 'notesPlain' not found in item '#{item}'."
    exit 1
  end
  notes_field['value'] = yaml_content

  stdout, stderr, status = Open3.capture3(
    'op', 'item', 'edit', "--vault=#{vault}", item,
    stdin_data: JSON.generate(item_data)
  )

  unless status.success?
    warn stderr unless stderr.empty?
    warn "Failed to update '#{item}' in 1Password vault '#{vault}'."
    exit 1
  end
end
