# frozen_string_literal: false
#
# tk/checkbutton.rb : treat checkbutton widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/checkbutton.html
#
require 'tk/radiobutton'

class Tk::CheckButton<Tk::RadioButton
  include Tk::Generated::Checkbutton
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
  #   :disabledforeground
  #   :font
  #   :foreground
  #   :height
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :image
  #   :indicatoron
  #   :justify
  #   :offrelief
  #   :offvalue
  #   :onvalue
  #   :overrelief
  #   :padx
  #   :pady
  #   :relief
  #   :selectcolor
  #   :selectimage
  #   :state
  #   :takefocus
  #   :text
  #   :textvariable (tkvariable)
  #   :tristateimage
  #   :tristatevalue
  #   :underline
  #   :variable (tkvariable)
  #   :width
  #   :wraplength
  # @generated:options:end

  TkCommandNames = ['checkbutton'.freeze].freeze
  WidgetClassName = 'Checkbutton'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def toggle
    tk_send_without_enc('toggle')
    self
  end
end

Tk::Checkbutton = Tk::CheckButton
#TkCheckButton = Tk::CheckButton unless Object.const_defined? :TkCheckButton
#TkCheckbutton = Tk::Checkbutton unless Object.const_defined? :TkCheckbutton
#Tk.__set_toplevel_aliases__(:Tk, Tk::CheckButton,
#                            :TkCheckButton, :TkCheckbutton)
Tk.__set_loaded_toplevel_aliases__('tk/checkbutton.rb', :Tk, Tk::CheckButton,
                                   :TkCheckButton, :TkCheckbutton)
