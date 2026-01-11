# frozen_string_literal: true

require_relative 'option'

module Tk
  # DSL for declaring widget options at the class level.
  #
  # Example:
  #   class MyWidget
  #     extend Tk::OptionDSL
  #
  #     option :text
  #     option :width, type: :integer
  #     option :bg, type: :color, aliases: [:background]
  #   end
  #
  #   MyWidget.options[:text]      # => Tk::Option
  #   MyWidget.resolve_option(:bg) # => Tk::Option (same as :background)
  #
  # Bridge Integration:
  #   When mixed into a class that also includes TkConfigMethod, the DSL
  #   automatically feeds into the legacy __*_optkeys methods so existing
  #   configure/cget code keeps working during migration.
  #
  module OptionDSL
    # Maps our type names to the legacy __*_optkeys method categories
    LEGACY_TYPE_MAP = {
      integer: :numval,
      float: :numval,
      boolean: :boolval,
      string: :strval,
      color: :strval,    # colors treated as strings in legacy system
      relief: :strval,   # relief values treated as strings
      pixels: :strval,   # pixel values treated as strings (can be "10" or "10p")
      anchor: :strval,   # anchor values treated as strings
      list: :listval,
      widget: :strval,   # widget paths are strings, but from_tcl converts to objects
    }.freeze

    # Called when module is extended into a class
    # Merge with existing options (from parent) instead of resetting
    def self.extended(base)
      existing = base.instance_variable_get(:@_options) || {}
      base.instance_variable_set(:@_options, existing.dup)
    end

    # Inherit options from parent class
    def inherited(subclass)
      super
      subclass.instance_variable_set(:@_options, _options.dup)
    end

    # Declare an option for this widget class.
    #
    # @param name [Symbol] Ruby-facing option name
    # @param type [Symbol] Type converter (:string, :integer, :boolean, etc.)
    # @param tcl_name [String, nil] Tcl option name if different from Ruby name
    # @param aliases [Array<Symbol>] Alternative names for this option
    # @param min_version [Integer, nil] Minimum Tcl/Tk major version required (e.g., 9 for Tk 9.0+)
    # @param from_tcl [Proc, nil] Custom converter for Tcl->Ruby (receives value, widget: keyword)
    # @param to_tcl [Proc, nil] Custom converter for Ruby->Tcl (receives value, widget: keyword)
    #
    def option(name, type: :string, tcl_name: nil, alias: nil, aliases: [], min_version: nil,
               from_tcl: nil, to_tcl: nil)
      # Support both alias: :foo (single) and aliases: [:foo, :bar] (multiple)
      all_aliases = Array(binding.local_variable_get(:alias)) + Array(aliases)
      all_aliases.compact!

      # Check for conflicts with existing option (e.g., from parent class)
      existing = _options[name.to_sym]
      if existing
        if existing.type.name == type && existing.aliases.sort == all_aliases.sort
          return # Same config, already inherited - skip silently
        else
          # Different config - warn but allow override (may be intentional)
          class_name = self.name || self.inspect
          warn "[ruby-tk] Option :#{name} redefined with different config in #{class_name}. " \
            "Was: type=#{existing.type.name}, aliases=#{existing.aliases}. " \
            "Now: type=#{type}, aliases=#{all_aliases}"
        end
      end

      opt = Option.new(name: name, tcl_name: tcl_name, type: type, aliases: all_aliases,
                       min_version: min_version, from_tcl: from_tcl, to_tcl: to_tcl)
      _options[opt.name] = opt
      all_aliases.each { |a| _options[a.to_sym] = opt }
    end

    # All declared options (including aliases pointing to same Option)
    def options
      _options.dup
    end

    # Look up an option by name or alias
    #
    # @param name [Symbol, String] Option name or alias
    # @return [Tk::Option, nil]
    #
    def resolve_option(name)
      _options[name.to_sym]
    end

    # List of canonical option names (excludes aliases)
    def option_names
      _options.values.uniq.map(&:name)
    end

    # Check if an option requires a newer Tcl/Tk version than currently running.
    # Returns the required version number if unavailable, nil if available or unknown.
    #
    # @param name [Symbol, String] Option name to check
    # @return [Integer, nil] Required version if unavailable, nil if available
    #
    def option_version_required(name)
      opt = resolve_option(name)
      return nil unless opt
      opt.version_required
    end

    # Bridge methods for legacy __*_optkeys compatibility
    # These return arrays of option names matching each legacy category

    def declared_numval_optkeys
      options_by_legacy_type(:numval)
    end

    def declared_boolval_optkeys
      options_by_legacy_type(:boolval)
    end

    def declared_strval_optkeys
      options_by_legacy_type(:strval)
    end

    def declared_listval_optkeys
      options_by_legacy_type(:listval)
    end

    def declared_optkey_aliases
      _options.values.uniq.each_with_object({}) do |opt, hash|
        opt.aliases.each { |a| hash[a] = opt.name }
      end
    end

    # Resolve aliases in a hash of options. Modifies hash in place.
    # Call as: self.class.resolve_option_aliases(options_hash)
    def resolve_option_aliases(hash)
      declared_optkey_aliases.each do |alias_name, real_name|
        alias_name = alias_name.to_s
        if hash.key?(alias_name)
          hash[real_name.to_s] = hash.delete(alias_name)
        end
      end
      hash
    end

    # Resolve a single option name, returning canonical name if alias.
    # Call as: self.class.resolve_option_alias(name)
    def resolve_option_alias(name)
      name = name.to_s
      _, real_name = declared_optkey_aliases.find { |k, _| k.to_s == name }
      real_name ? real_name.to_s : name
    end

    private

    def _options
      @_options ||= {}
    end

    def options_by_legacy_type(legacy_type)
      all_options_with_ancestors.select do |opt|
        LEGACY_TYPE_MAP[opt.type.name] == legacy_type
      end.map { |opt| opt.tcl_name }
    end

    def all_options_with_ancestors
      result = _options.values
      ancestors.each do |ancestor|
        next if ancestor == self
        if ancestor.respond_to?(:_options, true) && ancestor.instance_variable_defined?(:@_options)
          result += ancestor.instance_variable_get(:@_options).values
        end
      end
      result.uniq
    end
  end
end
