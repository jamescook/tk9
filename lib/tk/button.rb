# frozen_string_literal: false
#
# tk/button.rb : treat button widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/button.html
#
require 'tk' unless defined?(Tk)
require 'tk/label'
require 'tk/option_dsl'

class Tk::Button<Tk::Label
  extend Tk::OptionDSL

  TkCommandNames = ['button'.freeze].freeze
  WidgetClassName = 'Button'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Button-specific options (inherits all other options from Tk::Label)
  option :default,   type: :string    # normal, active, disabled
  option :overrelief, type: :relief   # relief when cursor is over button

  def invoke
    _fromUTF8(tk_send_without_enc('invoke'))
  end
  def flash
    tk_send_without_enc('flash')
    self
  end
end

#TkButton = Tk::Button unless Object.const_defined? :TkButton
#Tk.__set_toplevel_aliases__(:Tk, Tk::Button, :TkButton)
Tk.__set_loaded_toplevel_aliases__('tk/button.rb', :Tk, Tk::Button, :TkButton)
