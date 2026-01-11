# frozen_string_literal: false
#
#  tkextlib/bwidget/label.rb
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk' unless defined?(Tk)
require 'tk/label'
require 'tkextlib/bwidget.rb'

module Tk
  module BWidget
    class Label < Tk::Label
    end
  end
end

class Tk::BWidget::Label
  extend Tk::OptionDSL

  TkCommandNames = ['Label'.freeze].freeze
  WidgetClassName = 'Label'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # BWidget Label options
  option :helptext, type: :string
  option :helpvar, type: :tkvariable
  option :dragenabled, type: :boolean
  option :dropenabled, type: :boolean

  def set_focus
    tk_send_without_enc('setfocus')
    self
  end
end
