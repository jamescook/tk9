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
        # Use to_i to handle Tcl dimension strings like "10c" (centimeters)
        from_tcl: ->(v) { v.to_s.empty? ? nil : v.to_s.to_i }
      )

      Float = OptionType.new(:float,
        to_tcl: ->(v) { v.to_f.to_s },
        # Use to_f to handle Tcl dimension strings like "1.5i" (inches)
        from_tcl: ->(v) { v.to_s.empty? ? nil : v.to_s.to_f }
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
      # to_tcl: accepts symbol or string (e.g., :nw or "nw")
      # from_tcl: returns string for backwards compatibility
      Anchor = OptionType.new(:anchor,
        to_tcl: :to_s,
        from_tcl: :to_s
      )

      # Relief style (flat, raised, sunken, groove, ridge, solid)
      # to_tcl: accepts symbol or string (e.g., :raised or "raised")
      # from_tcl: returns string for backwards compatibility
      Relief = OptionType.new(:relief,
        to_tcl: :to_s,
        from_tcl: :to_s
      )

      # Widget reference - converts Tcl path to Ruby widget object
      Widget = OptionType.new(:widget,
        to_tcl: ->(v, widget:) { v.respond_to?(:path) ? v.path : v.to_s },
        from_tcl: ->(v, widget:) {
          path = v.to_s
          return nil unless path =~ /^\./
          found = TkCore::INTERP.tk_windows[path]
          unless found
            warn "Widget type: '#{path}' not in Ruby widget table, generating wrapper (this may indicate a problem)"
            found = TkComm._genobj_for_tkwidget(path)
          end
          found
        }
      )

      # TkVariable reference - converts Tcl variable name to TkVarAccess
      # Used for textvariable, variable, listvariable options
      TkVariable = OptionType.new(:tkvariable,
        to_tcl: ->(v) { v.respond_to?(:id) ? v.id : v.to_s },
        from_tcl: ->(v) { v.to_s.empty? ? nil : TkVarAccess.new(v) }
      )

      # Font - wraps font string in TkFont for backwards compatibility
      # Allows font.weight('bold') style method chaining
      # Uses TkFont.id2obj to return the same TkFont object if already registered
      # Passes widget reference so font setters can reconfigure the widget
      Font = OptionType.new(:font,
        to_tcl: ->(v) { v.to_s },
        from_tcl: ->(v, widget:) {
          return nil if v.to_s.empty?
          existing = TkFont.id2obj(v)
          return existing if existing
          # Create new TkFont with widget reference for auto-reconfigure
          TkFont.new(v, nil, widget: widget)
        }
      )

      # Callback - Tcl command string, typically registered via install_cmd
      # to_tcl: proc/lambda gets registered and returns callback ID
      # from_tcl: returns the raw Tcl command string (can't recover proc)
      Callback = OptionType.new(:callback,
        to_tcl: ->(v, widget:) {
          if v.respond_to?(:call)
            # Register the proc and return callback ID
            widget.install_cmd(v) if widget
          else
            v.to_s
          end
        },
        from_tcl: ->(v) { v.to_s }
      )

      # Canvas tags - converts space-separated tag names to TkcTag objects
      # Looks up registered tags via the canvas widget's canvastagid2obj method
      CanvasTags = OptionType.new(:canvas_tags,
        to_tcl: ->(v, widget:) {
          Array(v).map { |t| t.respond_to?(:id) ? t.id : t.to_s }.join(' ')
        },
        from_tcl: ->(v, widget:) {
          return [] if v.to_s.empty?
          tag_names = v.to_s.split
          tag_names.map { |tag_name| widget.canvastagid2obj(tag_name) }
        }
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
