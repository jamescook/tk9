# frozen_string_literal: false
#
# tk/radiobutton.rb : treat radiobutton widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/radiobutton.html
#
require 'tk/button'

class Tk::RadioButton<Tk::Button
  include Tk::Generated::Radiobutton
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
  #   :value
  #   :variable (tkvariable)
  #   :width
  #   :wraplength
  # @generated:options:end

  TkCommandNames = ['radiobutton'.freeze].freeze
  WidgetClassName = 'Radiobutton'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def deselect
    tk_send_without_enc('deselect')
    self
  end
  def select
    tk_send_without_enc('select')
    self
  end

  def get_value
    var = tk_send_without_enc('cget', '-variable')
    if TkVariable::USE_TCLs_SET_VARIABLE_FUNCTIONS
      INTERP._get_global_var(var)
    else
      INTERP._eval(Kernel.format('global %s; set %s', var, var))
    end
  end

  def set_value(val)
    var = tk_send_without_enc('cget', '-variable')
    if TkVariable::USE_TCLs_SET_VARIABLE_FUNCTIONS
      INTERP._set_global_var(var, _get_eval_string(val, true))
    else
      s = '"' + _get_eval_string(val).gsub(/[\[\]$"\\]/, '\\\\\&') + '"'
      INTERP._eval(Kernel.format('global %s; set %s %s', var, var, s))
    end
  end
end

Tk::Radiobutton = Tk::RadioButton
#TkRadioButton = Tk::RadioButton unless Object.const_defined? :TkRadioButton
#TkRadiobutton = Tk::Radiobutton unless Object.const_defined? :TkRadiobutton
#Tk.__set_toplevel_aliases__(:Tk, Tk::RadioButton,
#                            :TkRadioButton, :TkRadiobutton)
Tk.__set_loaded_toplevel_aliases__('tk/radiobutton.rb', :Tk, Tk::RadioButton,
                                   :TkRadioButton, :TkRadiobutton)
