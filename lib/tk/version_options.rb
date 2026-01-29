# frozen_string_literal: true

module Tk
  # Metadata about version-specific widget options.
  # Tracks when options were introduced or removed across Tcl/Tk versions.
  #
  # Used at generation time (rake tasks) to annotate options with version info.
  # The generated code then uses simple version checks at runtime.
  #
  module VersionOptions
    # Options with version requirements.
    # Format: 'widget_cmd' => { 'option_name' => { min_version: 'M.m', max_version: 'M.m' } }
    #
    # Only options that differ from "always available" need entries here.
    # Version strings like "9.0", "8.6", "10.0" etc.
    #
    OPTION_VERSIONS = {
      # Classic Tk widgets
      'entry' => {
        'placeholder' => { min_version: '9.0' },
        'placeholderforeground' => { min_version: '9.0' },
      },
      'frame' => {
        'backgroundimage' => { min_version: '9.0' },
        'tile' => { min_version: '9.0' },
      },
      'menu' => {
        'activerelief' => { min_version: '9.0' },
      },
      'spinbox' => {
        'placeholder' => { min_version: '9.0' },
        'placeholderforeground' => { min_version: '9.0' },
      },
      'toplevel' => {
        'backgroundimage' => { min_version: '9.0' },
        'tile' => { min_version: '9.0' },
      },

      # Ttk widgets
      'ttk::button' => {
        'justify' => { min_version: '9.0' },
      },
      'ttk::checkbutton' => {
        'justify' => { min_version: '9.0' },
      },
      'ttk::combobox' => {
        'placeholder' => { min_version: '9.0' },
        'placeholderforeground' => { min_version: '9.0' },
      },
      'ttk::entry' => {
        'placeholder' => { min_version: '9.0' },
        'placeholderforeground' => { min_version: '9.0' },
      },
      'ttk::menubutton' => {
        'justify' => { min_version: '9.0' },
      },
      'ttk::progressbar' => {
        'anchor' => { min_version: '9.0' },
        'font' => { min_version: '9.0' },
        'foreground' => { min_version: '9.0' },
        'justify' => { min_version: '9.0' },
        'text' => { min_version: '9.0' },
        'wraplength' => { min_version: '9.0' },
      },
      'ttk::radiobutton' => {
        'justify' => { min_version: '9.0' },
      },
      'ttk::spinbox' => {
        'placeholder' => { min_version: '9.0' },
        'placeholderforeground' => { min_version: '9.0' },
      },
      'ttk::treeview' => {
        'selecttype' => { min_version: '9.0' },
        'striped' => { min_version: '9.0' },
        'titlecolumns' => { min_version: '9.0' },
        'titleitems' => { min_version: '9.0' },
      },
    }.freeze

    class << self
      # Parse version string to [major, minor] array
      # @param version_str [String] e.g., "9.0", "8.6"
      # @return [Array<Integer>] [major, minor]
      def parse_version(version_str)
        parts = version_str.to_s.split('.')
        [parts[0].to_i, parts[1].to_i]
      end

      # Get version info for an option
      # @param widget_cmd [String] Tcl widget command (e.g., 'button', 'ttk::entry')
      # @param option_name [String, Symbol] Option name
      # @return [Hash, nil] { min_version: 'M.m', max_version: 'M.m' } or nil if always available
      def version_info(widget_cmd, option_name)
        widget_opts = OPTION_VERSIONS[widget_cmd.to_s]
        widget_opts && widget_opts[option_name.to_s]
      end

      # Check if an option is available for a given Tk version
      # @param widget_cmd [String] Tcl widget command
      # @param option_name [String, Symbol] Option name
      # @param tk_version [String] Version to check against (e.g., "8.6", "9.0")
      # @return [Boolean]
      def available?(widget_cmd, option_name, tk_version)
        info = version_info(widget_cmd, option_name)
        return true unless info

        current = parse_version(tk_version)

        if info[:min_version]
          required = parse_version(info[:min_version])
          return false if compare_versions(current, required) < 0
        end

        if info[:max_version]
          max = parse_version(info[:max_version])
          return false if compare_versions(current, max) > 0
        end

        true
      end

      # Get the minimum version required for an option
      # @return [String, nil] e.g., "9.0" or nil
      def min_version(widget_cmd, option_name)
        info = version_info(widget_cmd, option_name)
        info && info[:min_version]
      end

      # Get the maximum version for an option (after which it was removed)
      # @return [String, nil] e.g., "8.6" or nil
      def max_version(widget_cmd, option_name)
        info = version_info(widget_cmd, option_name)
        info && info[:max_version]
      end

      # List all options for a widget that require a specific minimum version
      # @param widget_cmd [String] Tcl widget command
      # @param version [String] Version (e.g., "9.0")
      # @return [Array<String>] Option names requiring that min_version
      def options_with_min_version(widget_cmd, version)
        widget_opts = OPTION_VERSIONS[widget_cmd.to_s]
        return [] unless widget_opts

        widget_opts.select { |_, info| info[:min_version] == version }.keys
      end

      private

      # Compare two parsed versions
      # @return [Integer] -1 if a < b, 0 if equal, 1 if a > b
      def compare_versions(a, b)
        (a[0] <=> b[0]).nonzero? || (a[1] <=> b[1])
      end
    end
  end
end
