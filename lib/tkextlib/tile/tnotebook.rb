# frozen_string_literal: false
#
#  tnotebook widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_notebook.html
#
require 'tk' unless defined?(Tk)
require 'tk/option_dsl'
require 'tk/item_option_dsl'
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class TNotebook < TkWindow
    end
    Notebook = TNotebook
  end
end

class Tk::Tile::TNotebook < TkWindow
  extend Tk::OptionDSL
  extend Tk::ItemOptionDSL
  ################################
  include TkItemConfigMethod

  def __item_cget_cmd(id)
    [self.path, 'tab', id]
  end
  private :__item_cget_cmd

  def __item_config_cmd(id)
    [self.path, 'tab', id]
  end
  private :__item_config_cmd

  def __item_methodcall_optkeys(id)  # { key=>method, ... }
    {}
  end
  private :__item_methodcall_optkeys

  #alias tabcget itemcget
  #alias tabcget_strict itemcget_strict
  alias tabconfigure itemconfigure
  alias tabconfiginfo itemconfiginfo
  alias current_tabconfiginfo current_itemconfiginfo

  def tabcget_tkstring(tagOrId, option)
    tk_split_simplelist(tk_call_without_enc(*(__item_confinfo_cmd(tagid(tagOrId)) << "-#{option}")), false, true)[-1]
  end
  def tabcget_strict(tagOrId, option)
    tabconfiginfo(tagOrId, option)[-1]
  end
  def tabcget(tagOrId, option)
    tabcget_strict(tagOrId, option)
  end
  ################################

  include Tk::Tile::TileWidget

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::notebook'.freeze].freeze
  else
    TkCommandNames = ['::tnotebook'.freeze].freeze
  end
  WidgetClassName = 'TNotebook'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Widget-specific options
  option :height,  type: :pixels     # pane area height
  option :padding, type: :string     # outer padding
  option :width,   type: :pixels     # pane area width
  option :style,   type: :string     # ttk style

  # ================================================================
  # Item options (for notebook tabs)
  # ================================================================

  # String options
  item_option :text,      type: :string    # tab label
  item_option :image,     type: :string    # tab icon
  item_option :compound,  type: :string    # text/image position (none, text, image, center, top, bottom, left, right)
  item_option :state,     type: :string    # normal, disabled, hidden
  item_option :sticky,    type: :string    # child widget sticky (n, s, e, w combinations)
  item_option :padding,   type: :string    # internal padding

  # Integer options
  item_option :underline, type: :integer   # underline character index

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end

  def enable_traversal()
    if Tk::Tile::TILE_SPEC_VERSION_ID < 5
      tk_call_without_enc('::tile::enableNotebookTraversal', @path)
    elsif Tk::Tile::TILE_SPEC_VERSION_ID < 7
      tk_call_without_enc('::tile::notebook::enableTraversal', @path)
    else
      tk_call_without_enc('::ttk::notebook::enableTraversal', @path)
    end
    self
  end

  def add(child, keys=nil)
    if keys && keys != None
      tk_send('add', _epath(child), *hash_kv(keys))
    else
      tk_send('add', _epath(child))
    end
    self
  end

  def forget(idx)
    tk_send('forget', idx)
    self
  end

  def hide(idx)
    tk_send('hide', idx)
  end

  def index(idx)
    number(tk_send('index', idx))
  end

  def insert(idx, subwin, keys=nil)
    if keys && keys != None
      tk_send('insert', idx, subwin, *hash_kv(keys))
    else
      tk_send('insert', idx, subwin)
    end
    self
  end

  def select(idx)
    tk_send('select', idx)
    self
  end

  def selected
    window(tk_send_without_enc('select'))
  end

  def tabs
    list(tk_send('tabs'))
  end
end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Notebook, :TkNotebook)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/tnotebook.rb',
                                   :Ttk, Tk::Tile::Notebook, :TkNotebook)
