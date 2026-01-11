# frozen_string_literal: true

require_relative 'option'

module Tk
  # DSL for declaring item options at the class level.
  #
  # This is the item configuration equivalent of OptionDSL. Use it for widgets
  # that have configurable sub-elements (Canvas items, Text tags, Menu entries,
  # Listbox items, Treeview items/columns/headings/tags, Notebook tabs, etc.)
  #
  # Example:
  #   class TkCanvas
  #     extend Tk::OptionDSL
  #     extend Tk::ItemOptionDSL
  #
  #     # Widget options
  #     option :width, type: :integer
  #
  #     # Item options (for rectangles, ovals, lines, text, etc.)
  #     item_option :fill, type: :color
  #     item_option :outline, type: :color
  #     item_option :width, type: :integer
  #     item_option :smooth, type: :boolean
  #   end
  #
  # Bridge Integration:
  #   When mixed into a class that also includes TkItemConfigMethod, the DSL
  #   automatically feeds into the legacy __item_*_optkeys methods so existing
  #   itemconfigure/itemcget code keeps working during migration.
  #
  module ItemOptionDSL
    # Maps our type names to the legacy __item_*_optkeys method categories
    LEGACY_TYPE_MAP = {
      integer: :numval,
      float: :numval,
      boolean: :boolval,
      string: :strval,
      list: :listval,
    }.freeze

    # Called when module is extended into a class
    def self.extended(base)
      base.instance_variable_set(:@_item_options, {})
    end

    # Inherit item options from parent class
    def inherited(subclass)
      super
      if instance_variable_defined?(:@_item_options)
        subclass.instance_variable_set(:@_item_options, _item_options.dup)
      end
    end

    # Declare an item option for this widget class.
    #
    # @param name [Symbol] Ruby-facing option name
    # @param type [Symbol] Type converter (:string, :integer, :boolean, etc.)
    # @param tcl_name [String, nil] Tcl option name if different from Ruby name
    # @param aliases [Array<Symbol>] Alternative names for this option
    #
    def item_option(name, type: :string, tcl_name: nil, aliases: [])
      opt = Option.new(name: name, tcl_name: tcl_name, type: type, aliases: aliases)
      _item_options[opt.name] = opt
      aliases.each { |a| _item_options[a.to_sym] = opt }
    end

    # All declared item options (including aliases pointing to same Option)
    def item_options
      _item_options.dup
    end

    # Look up an item option by name or alias
    #
    # @param name [Symbol, String] Option name or alias
    # @return [Tk::Option, nil]
    #
    def resolve_item_option(name)
      _item_options[name.to_sym]
    end

    # List of canonical item option names (excludes aliases)
    def item_option_names
      _item_options.values.uniq.map(&:name)
    end

    # Bridge methods for legacy __item_*_optkeys compatibility
    # These return arrays of option tcl_names matching each legacy category

    def declared_item_numval_optkeys
      item_options_by_legacy_type(:numval)
    end

    def declared_item_boolval_optkeys
      item_options_by_legacy_type(:boolval)
    end

    def declared_item_strval_optkeys
      item_options_by_legacy_type(:strval)
    end

    def declared_item_listval_optkeys
      item_options_by_legacy_type(:listval)
    end

    def declared_item_optkey_aliases
      _item_options.values.uniq.each_with_object({}) do |opt, hash|
        opt.aliases.each { |a| hash[a] = opt.name }
      end
    end

    private

    def _item_options
      @_item_options ||= {}
    end

    def item_options_by_legacy_type(legacy_type)
      _item_options.values.uniq.select do |opt|
        LEGACY_TYPE_MAP[opt.type.name] == legacy_type
      end.map { |opt| opt.tcl_name }
    end
  end
end
