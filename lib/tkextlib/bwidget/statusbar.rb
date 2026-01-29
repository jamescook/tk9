# frozen_string_literal: false
#
#  tkextlib/bwidget/statusbar.rb
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk'
require 'tk/frame'
require 'tkextlib/bwidget.rb'

module Tk
  module BWidget
    class StatusBar < TkWindow
    end
  end
end

class Tk::BWidget::StatusBar
  TkCommandNames = ['StatusBar'.freeze].freeze
  WidgetClassName = 'StatusBar'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def add(win, keys={})
    tk_send('add', win, keys)
    self
  end

  def remove(*wins)
    tk_send('remove', *wins)
    self
  end

  def remove_with_destroy(*wins)
    tk_send('remove', '-destroy', *wins)
    self
  end

  def delete(*wins) # same to 'remove_with_destroy'
    tk_send('delete', *wins)
    self
  end

  def get_frame(&b)
    win = window(tk_send_without_enc('getframe'))
    win.instance_exec(self, &b) if b
    win
  end

  # Returns all items in the statusbar, including auto-generated separators.
  # BWidget intentionally stores separators by name only (via [winfo name $sep])
  # while regular widgets get full paths. We normalize by prepending frame path.
  def items
    frame_path = tk_send_without_enc('getframe')
    simplelist(tk_send('items')).map do |w|
      w = "#{frame_path}.#{w}" unless w.start_with?('.')
      window(w)
    end
  end
end
