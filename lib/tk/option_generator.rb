# frozen_string_literal: true

require 'erb'
require_relative 'type_registry'
require_relative 'option_comments'

module Tk
  # Generates Option DSL declarations by introspecting Tk widgets at runtime.
  # Used by `rake tk:generate_options` to create version-specific option files.
  class OptionGenerator
    TEMPLATES_DIR = File.expand_path('templates', __dir__)
    # Represents a single option parsed from Tk's configure output
    class OptionEntry
      attr_reader :name, :db_name, :db_class, :default, :alias_target

      def initialize(name:, db_name: nil, db_class: nil, default: nil, alias_target: nil)
        @name = name
        @db_name = db_name
        @db_class = db_class
        @default = default
        @alias_target = alias_target
      end

      # Parse a raw Tk configure entry string
      # Full option: "-borderwidth borderWidth BorderWidth 2 2"
      # Alias: "-bd -borderwidth"
      def self.parse(raw)
        parts = raw.strip.split(/\s+/, 5)
        name = parts[0].sub(/^-/, '')

        if parts.size == 2 && parts[1].start_with?('-')
          # Alias entry
          new(name: name, alias_target: parts[1].sub(/^-/, ''))
        else
          # Full entry
          new(
            name: name,
            db_name: parts[1],
            db_class: parts[2],
            default: parts[3]
          )
        end
      end

      def alias?
        !@alias_target.nil?
      end

      def ruby_type
        return nil if alias?
        TypeRegistry.type_for(@db_class)
      end

      # Generate the DSL declaration for this option
      # @param aliases [Array<String>] optional list of alias names for this option
      def to_dsl(aliases: [])
        parts = ["option :#{name}"]

        if ruby_type && ruby_type != :string
          parts << "type: :#{ruby_type}"
        end

        if aliases.size == 1
          parts << "alias: :#{aliases.first}"
        elsif aliases.size > 1
          parts << "aliases: [#{aliases.map { |a| ":#{a}" }.join(', ')}]"
        end

        line = parts.join(', ')

        # Add human-friendly comment if available
        comment = OPTION_COMMENTS[name.to_sym]
        line += "  # #{comment}" if comment

        line
      end
    end

    attr_reader :tcl_version

    def initialize(tcl_version:)
      @tcl_version = tcl_version
    end

    # Introspect a widget and return array of OptionEntry objects
    # widget_cmd is the Tk command (e.g., "button", "entry", "ttk::button")
    def introspect_widget(widget_cmd)
      require 'tk'

      # Create temp widget
      path = ".#{widget_cmd.gsub('::', '_')}_introspect_#{$$}"
      TkCore::INTERP._invoke(widget_cmd, path)

      # Get configure output
      raw = TkCore::INTERP._invoke(path, "configure")

      # Destroy temp widget
      TkCore::INTERP._invoke("destroy", path)

      # Parse each entry
      parse_configure_output(raw)
    end

    # Parse raw configure output into OptionEntry array
    def parse_configure_output(raw)
      # Raw format: "{-opt1 ...} {-opt2 ...} ..."
      # Split on "} {" pattern
      entries = raw.scan(/\{([^}]+)\}/).flatten
      entries.map { |entry| OptionEntry.parse(entry) }
    end

    # Generate a Ruby module for a widget's options
    def generate_widget_module(widget_name, raw_options)
      entries = raw_options.map { |raw| OptionEntry.parse(raw) }
      generate_module_from_entries(widget_name, entries)
    end

    # Generate module code from parsed entries
    def generate_module_from_entries(widget_name, entries)
      # Group aliases by their target
      alias_map = {}
      entries.select(&:alias?).each do |entry|
        alias_map[entry.alias_target] ||= []
        alias_map[entry.alias_target] << entry.name
      end

      # Get regular options sorted alphabetically, with their aliases
      options_with_aliases = entries.reject(&:alias?).sort_by(&:name).map do |entry|
        aliases = (alias_map[entry.name] || []).sort
        { entry: entry, aliases: aliases }
      end

      template = File.read(File.join(TEMPLATES_DIR, 'widget_module.erb'))
      ERB.new(template, trim_mode: '-').result(binding)
    end

    # Generate the full options file for all widgets
    def generate_options_file(widgets)
      version_const = tcl_version.gsub('.', '_')
      timestamp = Time.now.utc.iso8601

      template = File.read(File.join(TEMPLATES_DIR, 'options_file.erb'))
      ERB.new(template, trim_mode: '-').result(binding)
    end

    # Helper for ERB template to render a single widget module
    def render_widget_module(widget_name, entries)
      generate_module_from_entries(widget_name, entries)
    end

    # Generate a standalone file for a single widget
    def generate_widget_file(widget_name, entries)
      # Group aliases by their target
      alias_map = {}
      entries.select(&:alias?).each do |entry|
        alias_map[entry.alias_target] ||= []
        alias_map[entry.alias_target] << entry.name
      end

      # Get regular options sorted alphabetically, with their aliases
      options_with_aliases = entries.reject(&:alias?).sort_by(&:name).map do |entry|
        aliases = (alias_map[entry.name] || []).sort
        { entry: entry, aliases: aliases }
      end

      template = File.read(File.join(TEMPLATES_DIR, 'widget_file.erb'))
      ERB.new(template, trim_mode: '-').result(binding)
    end
  end
end
