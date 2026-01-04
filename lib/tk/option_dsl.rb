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
      list: :listval,
    }.freeze

    # Called when module is extended into a class
    def self.extended(base)
      base.instance_variable_set(:@_options, {})
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
    #
    def option(name, type: :string, tcl_name: nil, aliases: [])
      opt = Option.new(name: name, tcl_name: tcl_name, type: type, aliases: aliases)
      _options[opt.name] = opt
      aliases.each { |a| _options[a.to_sym] = opt }
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

    private

    def _options
      @_options ||= {}
    end

    def options_by_legacy_type(legacy_type)
      _options.values.uniq.select do |opt|
        LEGACY_TYPE_MAP[opt.type.name] == legacy_type
      end.map { |opt| opt.tcl_name }
    end
  end
end
