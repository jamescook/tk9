# frozen_string_literal: false
#
#  tkextlib/bwidget/panedwindow.rb
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk' unless defined?(Tk)
require 'tk/frame'
require 'tkextlib/bwidget.rb'

module Tk
  module BWidget
    class PanedWindow < TkWindow
    end
  end
end

class Tk::BWidget::PanedWindow
  TkCommandNames = ['PanedWindow'.freeze].freeze
  WidgetClassName = 'PanedWindow'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def add(keys={})
    window(tk_send('add', *hash_kv(keys)))
  end

  def get_frame(idx, &b)
    win = window(tk_send_without_enc('getframe', idx))
    win.instance_exec(self, &b) if b
    win
  end
end
