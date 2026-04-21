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

def op_write_repositories(data, vault, item)
  _, status = Open3.capture2(
    'op', 'item', 'edit',
    "--vault=#{vault}",
    item,
    "notesPlain=#{data.to_yaml}"
  )

  unless status.success?
    warn "Failed to update '#{item}' in 1Password vault '#{vault}'."
    exit 1
  end
end
