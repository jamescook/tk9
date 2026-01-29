# frozen_string_literal: false
#
#  tcombobox widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_combobox.html
#
require 'tk'
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class TCombobox < Tk::Tile::TEntry
    end
    Combobox = TCombobox
  end
end

class Tk::Tile::TCombobox < Tk::Tile::TEntry
  include Tk::Tile::TileWidget
  include Tk::Generated::TtkCombobox

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::combobox'.freeze].freeze
  else
    TkCommandNames = ['::tcombobox'.freeze].freeze
  end
  WidgetClassName = 'TCombobox'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end

  def current
    number(tk_send_without_enc('current'))
  end
  def current=(idx)
    tk_send_without_enc('current', idx)
  end

  def set(val)
    tk_send('set', val)
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Combobox, :TkCombobox)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tcombobox.rb',
                                   :Ttk, Tk::Tile::Combobox, :TkCombobox)
