# frozen_string_literal: true

require_relative 'option_type'

module Tk
  # Metadata for a widget configuration option.
  #
  # Holds the option name, Tcl name, type converter, and any aliases.
  #
  # Example:
  #   opt = Tk::Option.new(name: :bg, tcl_name: 'background', type: :color, aliases: [:background])
  #   opt.to_tcl("red")   # => "red"
  #   opt.from_tcl("red") # => "red"
  #
  class Option
    attr_reader :name, :tcl_name, :type, :aliases

    def initialize(name:, tcl_name: nil, type: :string, aliases: [])
      @name = name.to_sym
      @tcl_name = (tcl_name || name).to_s
      @type = resolve_type(type)
      @aliases = Array(aliases).map(&:to_sym)
    end

    # Convert Ruby value to Tcl string
    def to_tcl(value, widget: nil)
      @type.to_tcl(value, widget: widget)
    end

    # Convert Tcl string to Ruby value
    def from_tcl(value, widget: nil)
      @type.from_tcl(value, widget: widget)
    end

    def inspect
      alias_str = @aliases.empty? ? "" : " aliases=#{@aliases}"
      "#<Tk::Option #{@name} tcl=#{@tcl_name} type=#{@type.name}#{alias_str}>"
    end

    private

    def resolve_type(type)
      case type
      when OptionType then type
      when Symbol, String then OptionType[type]
      else OptionType[:string]
      end
    end
  end
end
