# frozen_string_literal: false
#
#  tkextlib/bwidget/button.rb
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk' unless defined?(Tk)
require 'tk/button'
require 'tkextlib/bwidget.rb'

module Tk
  module BWidget
    class Button < Tk::Button
    end
  end
end

class Tk::BWidget::Button
  extend Tk::OptionDSL

  TkCommandNames = ['Button'.freeze].freeze
  WidgetClassName = 'Button'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # BWidget Button options
  option :helptext, type: :string

  def __tkvariable_optkeys
    super() << 'helpvar'
  end
  private :__tkvariable_optkeys
end
