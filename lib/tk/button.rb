# frozen_string_literal: false
#
# tk/button.rb : treat button widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/button.html
#
require 'tk/label'
require 'tk/option_dsl'

class Tk::Button<Tk::Label
  include Tk::Generated::Button
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :activebackground
  #   :activeforeground
  #   :anchor
  #   :background
  #   :bitmap
  #   :borderwidth
  #   :command (callback)
  #   :compound
  #   :cursor
  #   :default
  #   :disabledforeground
  #   :font
  #   :foreground
  #   :height
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :image
  #   :justify
  #   :overrelief
  #   :padx
  #   :pady
  #   :relief
  #   :repeatdelay
  #   :repeatinterval
  #   :state
  #   :takefocus
  #   :text
  #   :textvariable (tkvariable)
  #   :underline
  #   :width
  #   :wraplength
  # @generated:options:end



  TkCommandNames = ['button'.freeze].freeze
  WidgetClassName = 'Button'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def invoke
    tk_send_without_enc('invoke')
  end
  def flash
    tk_send_without_enc('flash')
    self
  end
end

#TkButton = Tk::Button unless Object.const_defined? :TkButton
#Tk.__set_toplevel_aliases__(:Tk, Tk::Button, :TkButton)
Tk.__set_loaded_toplevel_aliases__('tk/button.rb', :Tk, Tk::Button, :TkButton)
