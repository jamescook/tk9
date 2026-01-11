# frozen_string_literal: false
#
#  tentry widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_entry.html
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

  # Ttk-specific options (inherits from Tk::Entry)
  option :style,   type: :string
  option :validatecommand, type: :string, aliases: [:vcmd]
  option :invalidcommand,  type: :string, aliases: [:invcmd]

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Entry, :TkEntry)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tentry.rb',
                                   :Ttk, Tk::Tile::Entry, :TkEntry)
