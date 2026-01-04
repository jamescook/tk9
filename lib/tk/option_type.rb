# frozen_string_literal: true

module Tk
  # Handles conversion between Ruby values and Tcl strings for widget options.
  #
  # Each type defines:
  #   - to_tcl:   Ruby value -> Tcl string
  #   - from_tcl: Tcl string -> Ruby value
  #
  # Example:
  #   OptionType::Boolean.to_tcl(true)   # => "1"
  #   OptionType::Boolean.from_tcl("0")  # => false
  #
  class OptionType
    attr_reader :name

    def initialize(name, to_tcl:, from_tcl:)
      @name = name
      @to_tcl = to_tcl
      @from_tcl = from_tcl
    end

    def to_tcl(value, widget: nil)
      case @to_tcl
      when Symbol then value.send(@to_tcl)
      when Proc
        @to_tcl.arity == 1 ? @to_tcl.call(value) : @to_tcl.call(value, widget: widget)
      else
        value.to_s
      end
    end

    def from_tcl(value, widget: nil)
      case @from_tcl
      when Symbol then value.send(@from_tcl)
      when Proc
        @from_tcl.arity == 1 ? @from_tcl.call(value) : @from_tcl.call(value, widget: widget)
      else
        value
      end
    end

    def inspect
      "#<Tk::OptionType:#{@name}>"
    end

    # Built-in types
    module Types
      String = OptionType.new(:string,
        to_tcl: :to_s,
        from_tcl: :itself
      )

      Integer = OptionType.new(:integer,
        to_tcl: ->(v) { v.to_i.to_s },
        from_tcl: ->(v) { v.to_s.empty? ? nil : Integer(v) }
      )

      Float = OptionType.new(:float,
        to_tcl: ->(v) { v.to_f.to_s },
        from_tcl: ->(v) { v.to_s.empty? ? nil : Float(v) }
      )

      Boolean = OptionType.new(:boolean,
        to_tcl: ->(v) { v ? "1" : "0" },
        from_tcl: ->(v) { !v.to_s.match?(/^(0|false|no|off|)$/i) }
      )

      # List of strings
      List = OptionType.new(:list,
        to_tcl: ->(v) { Array(v).join(" ") },
        from_tcl: ->(v) { v.to_s.split }
      )

      # Pixels - can be integer or string with units (e.g., "10p", "2c")
      Pixels = OptionType.new(:pixels,
        to_tcl: :to_s,
        from_tcl: ->(v) { v =~ /^\d+$/ ? Integer(v) : v }
      )

      # Color - just a string but semantically distinct
      Color = OptionType.new(:color,
        to_tcl: :to_s,
        from_tcl: :itself
      )

      # Anchor position (n, ne, e, se, s, sw, w, nw, center)
      Anchor = OptionType.new(:anchor,
        to_tcl: :to_s,
        from_tcl: ->(v) { v.to_sym }
      )

      # Relief style (flat, raised, sunken, groove, ridge, solid)
      Relief = OptionType.new(:relief,
        to_tcl: :to_s,
        from_tcl: ->(v) { v.to_sym }
      )
    end

    # Registry for looking up types by name
    @registry = {}

    class << self
      def register(name, type)
        @registry[name.to_sym] = type
      end

      def [](name)
        @registry[name.to_sym] || Types::String
      end

      def registered?(name)
        @registry.key?(name.to_sym)
      end
    end

    # Register built-in types
    Types.constants.each do |const|
      type = Types.const_get(const)
      register(type.name, type) if type.is_a?(OptionType)
    end
  end
end
