# frozen_string_literal: false
#
# tk/label.rb : treat label widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/label.html
#
require 'tk/option_dsl'

class Tk::Label<TkWindow
  include Tk::Generated::Label
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :activebackground
  #   :activeforeground
  #   :anchor
  #   :background
  #   :bitmap
  #   :borderwidth
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
  #   :justify
  #   :padx
  #   :pady
  #   :relief
  #   :state
  #   :takefocus
  #   :text
  #   :textvariable (tkvariable)
  #   :underline
  #   :width
  #   :wraplength
  # @generated:options:end

  TkCommandNames = ['label'.freeze].freeze
  WidgetClassName = 'Label'.freeze
  WidgetClassNames[WidgetClassName] ||= self
  #def create_self(keys)
  #  if keys and keys != None
  #    tk_call_without_enc('label', @path, *hash_kv(keys, true))
  #  else
  #    tk_call_without_enc('label', @path)
  #  end
  #end
  #private :create_self
end

#TkLabel = Tk::Label unless Object.const_defined? :TkLabel
#Tk.__set_toplevel_aliases__(:Tk, Tk::Label, :TkLabel)
Tk.__set_loaded_toplevel_aliases__('tk/label.rb', :Tk, Tk::Label, :TkLabel)
