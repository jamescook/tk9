# frozen_string_literal: false
#
#  tbutton widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_button.html
#
require 'tk' unless defined?(Tk)
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class TButton < Tk::Button
    end
    Button = TButton
  end
end

class Tk::Tile::TButton < Tk::Button
  include Tk::Tile::TileWidget

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::button'.freeze].freeze
  else
    TkCommandNames = ['::tbutton'.freeze].freeze
  end
  WidgetClassName = 'TButton'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Ttk-specific options (inherits from Tk::Button)
  option :style,   type: :string
  option :default, type: :string  # normal, active, disabled

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Button, :TkButton)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tbutton.rb',
                                   :Ttk, Tk::Tile::Button, :TkButton)
