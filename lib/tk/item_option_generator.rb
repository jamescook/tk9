# frozen_string_literal: true

require 'erb'
require_relative 'type_registry'
require_relative 'item_type_registry'
require_relative 'option_generator'  # Reuse OptionEntry

module Tk
  # Generates Item Option DSL declarations by introspecting Tk widgets at runtime.
  # Used by `rake tk:generate_item_options` to create version-specific item option files.
  #
  # This mirrors OptionGenerator but for item-level configuration (canvas items,
  # menu entries, text tags, listbox items, etc.)
  #
  class ItemOptionGenerator
    TEMPLATES_DIR = File.expand_path('templates', __dir__)

    # Registry of widgets with items and their item types for introspection
    ITEM_TYPES = {
      canvas: {
        widget_cmd: 'canvas',
        item_types: {
          line: [0, 0, 100, 100],
          rectangle: [0, 0, 100, 100],
          oval: [0, 0, 100, 100],
          arc: [0, 0, 100, 100],
          polygon: [0, 0, 50, 100, 100, 0],
          text: [50, 50],
        },
        create_cmd: ->(path, type, coords) { "#{path} create #{type} #{coords.join(' ')}" },
        config_cmd: ->(path, id) { "#{path} itemconfigure #{id}" },
        delete_cmd: ->(path, id) { "#{path} delete #{id}" },
      },
      menu: {
        widget_cmd: 'menu',
        item_types: {
          command: nil,
          checkbutton: nil,
          radiobutton: nil,
          separator: nil,
          cascade: nil,
        },
        create_cmd: ->(path, type, _) { "#{path} add #{type}" },
        config_cmd: ->(path, _id) { "#{path} entryconfigure 0" },
        delete_cmd: ->(path, _id) { "#{path} delete 0" },
      },
      text: {
        widget_cmd: 'text',
        item_types: {
          tag: nil,
        },
        create_cmd: ->(path, _type, _) { "#{path} tag add testtag 1.0 1.0" },
        config_cmd: ->(path, _id) { "#{path} tag configure testtag" },
        delete_cmd: ->(path, _id) { "#{path} tag delete testtag" },
      },
      listbox: {
        widget_cmd: 'listbox',
        item_types: {
          item: nil,
        },
        create_cmd: ->(path, _type, _) { "#{path} insert end {test item}" },
        config_cmd: ->(path, _id) { "#{path} itemconfigure 0" },
        delete_cmd: ->(path, _id) { "#{path} delete 0" },
      },
    }.freeze

    attr_reader :tcl_version

    def initialize(tcl_version:)
      @tcl_version = tcl_version
    end

    # Introspect all item types for a widget and return flattened array of OptionEntry objects
    # @param widget_key [Symbol] Key in ITEM_TYPES (e.g., :canvas, :menu)
    # @return [Array<OptionGenerator::OptionEntry>] Unique options across all item types
    def introspect_widget_items(widget_key)
      require 'tk'

      config = ITEM_TYPES[widget_key]
      raise ArgumentError, "Unknown widget: #{widget_key}" unless config

      # Create widget
      path = ".#{widget_key}_item_introspect_#{$$}"
      TkCore::INTERP._invoke(config[:widget_cmd], path)

      all_entries = {}

      config[:item_types].each do |type, coords|
        # Create item
        create_cmd = config[:create_cmd].call(path, type, coords)
        id = TkCore::INTERP._eval(create_cmd)

        # Get configure output
        config_cmd = config[:config_cmd].call(path, id)
        raw = TkCore::INTERP._eval(config_cmd)

        # Parse entries (reuse OptionGenerator's parser)
        entries = parse_configure_output(raw)
        entries.each do |entry|
          # Keep first occurrence (flattening - all item types merged)
          all_entries[entry.name] ||= entry
        end

        # Delete item
        delete_cmd = config[:delete_cmd].call(path, id)
        TkCore::INTERP._eval(delete_cmd) rescue nil
      end

      # Destroy widget
      TkCore::INTERP._invoke("destroy", path)

      # Merge in known options that introspection may have missed
      # (e.g., Tcl 8.6 menu entryconfigure only returns 2 options in xvfb)
      known_options = ItemTypeRegistry.known_options_for(widget_key)
      known_options.each do |opt_name|
        next if all_entries.key?(opt_name)
        all_entries[opt_name] = OptionGenerator::OptionEntry.new(name: opt_name)
      end

      all_entries.values
    end

    # Parse raw configure output into OptionEntry array
    # Uses Tcl's list commands to handle nested braces correctly
    def parse_configure_output(raw)
      return [] if raw.nil? || raw.empty?

      result = []
      count = TkCore::INTERP._invoke('llength', raw).to_i
      count.times do |i|
        entry_raw = TkCore::INTERP._invoke('lindex', raw, i.to_s)
        len = TkCore::INTERP._invoke('llength', entry_raw).to_i
        name = TkCore::INTERP._invoke('lindex', entry_raw, '0').sub(/^-/, '')

        if len == 2
          # Alias: {-bd -borderwidth}
          target = TkCore::INTERP._invoke('lindex', entry_raw, '1').sub(/^-/, '')
          result << OptionGenerator::OptionEntry.new(name: name, alias_target: target)
        elsif len >= 4
          # Full: {-name dbName DbClass default current}
          db_name = TkCore::INTERP._invoke('lindex', entry_raw, '1')
          db_class = TkCore::INTERP._invoke('lindex', entry_raw, '2')
          default = TkCore::INTERP._invoke('lindex', entry_raw, '3')
          result << OptionGenerator::OptionEntry.new(name: name, db_name: db_name, db_class: db_class, default: default)
        end
      end
      result
    end

    # Generate module code from parsed entries
    def generate_module_from_entries(widget_name, entries)
      options_with_aliases = build_options_with_aliases(entries)

      template = File.read(File.join(TEMPLATES_DIR, 'item_options_widget.erb'))
      ERB.new(template, trim_mode: '-').result_with_hash(
        tcl_version: @tcl_version,
        widget_name: widget_name,
        options_with_aliases: options_with_aliases
      )
    end

    private

    def build_options_with_aliases(entries)
      alias_map = {}
      entries.select(&:alias?).each do |entry|
        alias_map[entry.alias_target] ||= []
        alias_map[entry.alias_target] << entry.name
      end

      entries.reject(&:alias?).sort_by(&:name).map do |entry|
        aliases = (alias_map[entry.name] || []).sort
        { entry: entry, aliases: aliases }
      end
    end

    # Generate a standalone file for a single widget's item options
    def generate_widget_file(widget_name, entries)
      generate_module_from_entries(widget_name, entries)
    end
  end
end
