# frozen_string_literal: false
#
#  tentry widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
require 'tk' unless defined?(Tk)
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class TEntry < Tk::Entry
    end
    Entry = TEntry
  end
end

class Tk::Tile::TEntry < Tk::Entry
  include Tk::Tile::TileWidget

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::entry'.freeze].freeze
  else
    TkCommandNames = ['::tentry'.freeze].freeze
  end
  WidgetClassName = 'TEntry'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Options added in Tcl/Tk 9.0
  TCL9_OPTIONS = ['placeholder', 'placeholderforeground'].freeze

  def __optkey_aliases
    {:vcmd=>:validatecommand, :invcmd=>:invalidcommand}
  end
  private :__optkey_aliases

  def __boolval_optkeys
    super() << 'exportselection'
  end
  private :__boolval_optkeys

  def __strval_optkeys
    keys = super() << 'show'
    # Add placeholder options for Tcl/Tk 9.0+
    if Tk::TCL_MAJOR_VERSION >= 9
      keys.concat(TCL9_OPTIONS)
    end
    keys
  end
  private :__strval_optkeys

  # Warn if Tcl 9 options used on Tcl 8.x
  def configure(slot, value=TkComm::None)
    if Tk::TCL_MAJOR_VERSION < 9 && slot.is_a?(Hash)
      TCL9_OPTIONS.each do |opt|
        if slot.key?(opt) || slot.key?(opt.to_sym)
          warn "Warning: '#{opt}' option requires Tcl/Tk 9.0+ (you have #{Tk::TCL_VERSION})"
          slot.delete(opt)
          slot.delete(opt.to_sym)
        end
      end
    elsif Tk::TCL_MAJOR_VERSION < 9 && TCL9_OPTIONS.include?(slot.to_s)
      warn "Warning: '#{slot}' option requires Tcl/Tk 9.0+ (you have #{Tk::TCL_VERSION})"
      return self
    end
    super
  end

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Entry, :TkEntry)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tentry.rb',
                                   :Ttk, Tk::Tile::Entry, :TkEntry)
