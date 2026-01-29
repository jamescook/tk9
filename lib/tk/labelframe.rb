# frozen_string_literal: false
#
# tk/labelframe.rb : treat labelframe widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/labelframe.html
#
require 'tk/frame'

class Tk::LabelFrame<Tk::Frame
  include Tk::Generated::Labelframe
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :background
  #   :borderwidth
  #   :class
  #   :colormap
  #   :container
  #   :cursor
  #   :font
  #   :foreground
  #   :height
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :labelanchor
  #   :labelwidget
  #   :padx
  #   :pady
  #   :relief
  #   :takefocus
  #   :text
  #   :visual
  #   :width
  # @generated:options:end

  TkCommandNames = ['labelframe'.freeze].freeze
  WidgetClassName = 'Labelframe'.freeze
  WidgetClassNames[WidgetClassName] ||= self
end

Tk::Labelframe = Tk::LabelFrame
#TkLabelFrame = Tk::LabelFrame unless Object.const_defined? :TkLabelFrame
#TkLabelframe = Tk::Labelframe unless Object.const_defined? :TkLabelframe
#Tk.__set_toplevel_aliases__(:Tk, Tk::LabelFrame, :TkLabelFrame, :TkLabelframe)
Tk.__set_loaded_toplevel_aliases__('tk/labelframe.rb', :Tk, Tk::LabelFrame,
                                   :TkLabelFrame, :TkLabelframe)
