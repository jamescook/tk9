# frozen_string_literal: false
#
#  tlabelframe widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_labelframe.html
#
require 'tk'
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class TLabelframe < Tk::Tile::TFrame
    end
    TLabelFrame = TLabelframe
    Labelframe  = TLabelframe
    LabelFrame  = TLabelframe
  end
end

class Tk::Tile::TLabelframe < Tk::Tile::TFrame
  include Tk::Tile::TileWidget
  include Tk::Generated::TtkLabelframe

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::labelframe'.freeze].freeze
  else
    TkCommandNames = ['::tlabelframe'.freeze].freeze
  end
  WidgetClassName = 'TLabelframe'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Labelframe,
#                            :TkLabelframe, :TkLabelFrame)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tlabelframe.rb',
                                   :Ttk, Tk::Tile::Labelframe,
                                   :TkLabelframe, :TkLabelFrame)
