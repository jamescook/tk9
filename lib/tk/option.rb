# frozen_string_literal: true

require_relative 'option_type'

module Tk
  # Metadata for a widget configuration option.
  #
  # Holds the option name, Tcl name, type converter, any aliases, and version requirements.
  #
  # Example:
  #   opt = Tk::Option.new(name: :bg, tcl_name: 'background', type: :color, aliases: [:background])
  #   opt.to_tcl("red")   # => "red"
  #   opt.from_tcl("red") # => "red"
  #
  #   # Version-restricted option (Tcl/Tk 9.0+)
  #   opt = Tk::Option.new(name: :activerelief, type: :relief, min_version: 9)
  #   opt.available?      # => false on Tk 8.6, true on Tk 9.0+
  #
  #   # Custom converters (for special cases like menu => window object)
  #   opt = Tk::Option.new(name: :menu, type: :string,
  #                        from_tcl: ->(v, widget:) { widget.window(v) })
  #
  class Option
    attr_reader :name, :tcl_name, :type, :aliases, :min_version

    # @param name [Symbol] Ruby-facing option name
    # @param tcl_name [String, nil] Tcl option name if different from Ruby name
    # @param type [Symbol] Type converter (:string, :integer, :boolean, etc.)
    # @param aliases [Array<Symbol>] Alternative names for this option
    # @param min_version [Integer, nil] Minimum Tcl/Tk major version required
    # @param from_tcl [Proc, nil] Custom converter for Tcl->Ruby
    # @param to_tcl [Proc, nil] Custom converter for Ruby->Tcl
    #
    def initialize(name:, tcl_name: nil, type: :string, aliases: [], min_version: nil,
                   from_tcl: nil, to_tcl: nil)
      @name = name.to_sym
      @tcl_name = (tcl_name || name).to_s
      @type = resolve_type(type)
      @aliases = Array(aliases).map(&:to_sym)
      @min_version = min_version
      @from_tcl_callback = from_tcl
      @to_tcl_callback = to_tcl
    end

    # Convert Ruby value to Tcl string
    # Custom to_tcl callback takes precedence over type converter
    def to_tcl(value, widget: nil)
      if @to_tcl_callback
        @to_tcl_callback.call(value, widget: widget)
      else
        @type.to_tcl(value, widget: widget)
      end
    end

    # Convert Tcl string to Ruby value
    # Custom from_tcl callback takes precedence over type converter
    def from_tcl(value, widget: nil)
      if @from_tcl_callback
        @from_tcl_callback.call(value, widget: widget)
      else
        @type.from_tcl(value, widget: widget)
      end
    end

    # Check if this option is available in the current Tcl/Tk version.
    # Returns true if no min_version is set, or if current version >= min_version.
    def available?
      return true unless @min_version
      available_for_version?(Tk::TK_VERSION)
    end

    # Check if this option is available for a specific Tk version string.
    # @param version_str [String] e.g., "8.6", "9.0"
    # @return [Boolean]
    def available_for_version?(version_str)
      return true unless @min_version
      compare_versions(version_str, min_version_str) >= 0
    end

    # Return min_version as a string (e.g., "9.0")
    # Handles both integer (legacy) and string formats
    def min_version_str
      return nil unless @min_version
      @min_version.is_a?(String) ? @min_version : "#{@min_version}.0"
    end

    # Check if this option requires a newer Tcl/Tk version than currently running.
    # Returns the required version if unavailable, nil if available.
    def version_required
      return nil if available?
      @min_version
    end

    def inspect
      alias_str = @aliases.empty? ? "" : " aliases=#{@aliases}"
      version_str = @min_version ? " min_version=#{@min_version}" : ""
      "#<Tk::Option #{@name} tcl=#{@tcl_name} type=#{@type.name}#{alias_str}#{version_str}>"
    end

    private

    def resolve_type(type)
      case type
      when OptionType then type
      when Symbol, String then OptionType[type]
      else OptionType[:string]
      end
    end

    def compare_versions(a, b)
      parse_version(a) <=> parse_version(b)
    end

    def parse_version(str)
      parts = str.to_s.split('.')
      [parts[0].to_i, parts[1].to_i]
    end
  end
end
