# frozen_string_literal: false
#
# tk/listbox.rb : treat listbox widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/listbox.html
#
require 'tk' unless defined?(Tk)
require 'tk/scrollable'
require 'tk/txtwin_abst'
require 'tk/option_dsl'
require 'tk/item_option_dsl'

class Tk::Listbox<TkTextWin
  extend Tk::ItemOptionDSL
  include Scrollable
  include Tk::Generated::Listbox
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :activestyle
  #   :background
  #   :borderwidth
  #   :cursor
  #   :disabledforeground
  #   :exportselection
  #   :font
  #   :foreground
  #   :height
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :justify
  #   :listvariable (tkvariable)
  #   :relief
  #   :selectbackground
  #   :selectborderwidth
  #   :selectforeground
  #   :selectmode
  #   :setgrid
  #   :state
  #   :takefocus
  #   :width
  #   :xscrollcommand
  #   :yscrollcommand
  # @generated:options:end



  TkCommandNames = ['listbox'.freeze].freeze
  WidgetClassName = 'Listbox'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Item options (for listbox items)
  item_option :background,        type: :string
  item_option :foreground,        type: :string
  item_option :selectbackground,  type: :string
  item_option :selectforeground,  type: :string

  #def create_self(keys)
  #  if keys and keys != None
  #    tk_call_without_enc('listbox', @path, *hash_kv(keys, true))
  #  else
  #    tk_call_without_enc('listbox', @path)
  #  end
  #end
  #private :create_self

  def tagid(id)
    #id.to_s
    _get_eval_string(id)
  end

  def activate(y)
    tk_send_without_enc('activate', y)
    self
  end
  def curselection
    list(tk_send_without_enc('curselection'))
  end
  def get(first, last=nil)
    if last
      # tk_split_simplelist(_fromUTF8(tk_send_without_enc('get', first, last)))
      tk_split_simplelist(tk_send_without_enc('get', first, last), false, true)
    else
      _fromUTF8(tk_send_without_enc('get', first))
    end
  end
  def nearest(y)
    tk_send_without_enc('nearest', y).to_i
  end
  def size
    tk_send_without_enc('size').to_i
  end
  def selection_anchor(index)
    tk_send_without_enc('selection', 'anchor', index)
    self
  end
  def selection_clear(first, last=None)
    tk_send_without_enc('selection', 'clear', first, last)
    self
  end
  def selection_includes(index)
    bool(tk_send_without_enc('selection', 'includes', index))
  end
  def selection_set(first, last=None)
    tk_send_without_enc('selection', 'set', first, last)
    self
  end

  def index(idx)
    tk_send_without_enc('index', idx).to_i
  end

  def value
    get('0', 'end')
  end

  def value=(vals)
    unless vals.kind_of?(Array)
      fail ArgumentError, 'an Array is expected'
    end
    tk_send_without_enc('delete', '0', 'end')
    tk_send_without_enc('insert', '0',
                        *(vals.collect{|v| _get_eval_enc_str(v)}))
    vals
  end

  def clear
    tk_send_without_enc('delete', '0', 'end')
    self
  end
  alias erase clear
end

#TkListbox = Tk::Listbox unless Object.const_defined? :TkListbox
#Tk.__set_toplevel_aliases__(:Tk, Tk::Listbox, :TkListbox)
Tk.__set_loaded_toplevel_aliases__('tk/listbox.rb', :Tk, Tk::Listbox,
                                   :TkListbox)
