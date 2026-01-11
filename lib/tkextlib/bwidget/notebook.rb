# frozen_string_literal: false
#
#  tkextlib/bwidget/notebook.rb
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk' unless defined?(Tk)
require 'tk/frame'
require 'tkextlib/bwidget.rb'

module Tk
  module BWidget
    class NoteBook < TkWindow
    end
  end
end

class Tk::BWidget::NoteBook
  extend Tk::OptionDSL
  include TkItemConfigMethod

  TkCommandNames = ['NoteBook'.freeze].freeze
  WidgetClassName = 'NoteBook'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # BWidget NoteBook options
  option :homogeneous, type: :boolean

  class Event_for_Tabs < TkEvent::Event
    def self._get_extra_args_tbl
      [
        TkComm.method(:string)   # page identifier
      ]
    end
  end

  def tagid(id)
    if id.kind_of?(TkWindow)
      #id.path
      id.epath
    elsif id.kind_of?(TkObject)
      id.to_eval
    else
      # id.to_s
      _get_eval_string(id)
    end
  end

  def tabbind(context, *args, &block)
    #if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind_for_event_class(Event_for_Tabs, [path, 'bindtabs'],
                          context, cmd, *args)
    self
  end

  def tabbind_append(context, *args, &block)
    #if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind_append_for_event_class(Event_for_Tabs, [path, 'bindtabs'],
                                 context, cmd, *args)
    self
  end

  def tabbind_remove(*args)
    _bind_remove_for_event_class(Event_for_Tabs, [path, 'bindtabs'], *args)
    self
  end

  def tabbindinfo(*args)
    _bindinfo_for_event_class(Event_for_Tabs, [path, 'bindtabs'], *args)
  end

  def add(page, &b)
    win = window(tk_send('add', tagid(page)))
    win.instance_exec(self, &b) if b
    win
  end

  def compute_size
    tk_send('compute_size')
    self
  end

  def delete(page, destroyframe=None)
    tk_send('delete', tagid(page), destroyframe)
    self
  end

  def get_frame(page, &b)
    win = window(tk_send('getframe', tagid(page)))
    win.instance_exec(self, &b) if b
    win
  end

  def index(page)
    num_or_str(tk_send('index', tagid(page)))
  end

  def insert(index, page, keys={}, &b)
    win = window(tk_send('insert', index, tagid(page), *hash_kv(keys)))
    win.instance_exec(self, &b) if b
    win
  end

  def move(page, index)
    tk_send('move', tagid(page), index)
    self
  end

  def get_page(page)
    tk_send('pages', page)
  end

  def pages(first=None, last=None)
    list(tk_send('pages', first, last))
  end

  def raise(page=nil)
    if page
      tk_send('raise', page)
      self
    else
      tk_send('raise')
    end
  end

  def see(page)
    tk_send('see', page)
    self
  end
end
