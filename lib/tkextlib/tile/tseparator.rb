# frozen_string_literal: false
#
#  tseparator widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_separator.html
#
require 'tk' unless defined?(Tk)
require 'tk/option_dsl'
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class TSeparator < TkWindow
    end
    Separator = TSeparator
  end
end

class Tk::Tile::TSeparator < TkWindow
  extend Tk::OptionDSL
  include Tk::Tile::TileWidget

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::separator'.freeze].freeze
  else
    TkCommandNames = ['::tseparator'.freeze].freeze
  end
  WidgetClassName = 'TSeparator'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Widget-specific options
  option :orient, type: :string   # horizontal, vertical
  option :style,  type: :string   # ttk style

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Separator, :TkSeparator)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tseparator.rb',
                                   :Ttk, Tk::Tile::Separator, :TkSeparator)
