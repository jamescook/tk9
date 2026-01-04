# frozen_string_literal: false
#
# tk/label.rb : treat label widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/label.html
#
require 'tk' unless defined?(Tk)
require 'tk/option_dsl'

class Tk::Label<TkWindow
  extend Tk::OptionDSL

  TkCommandNames = ['label'.freeze].freeze
  WidgetClassName = 'Label'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Standard options (shared with many widgets)
  option :anchor,      type: :anchor     # n, ne, e, se, s, sw, w, nw, center
  option :borderwidth, type: :pixels, aliases: [:bd]
  option :compound,    type: :string     # none, bottom, top, left, right, center
  option :justify,     type: :string     # left, center, right
  option :padx,        type: :pixels
  option :pady,        type: :pixels
  option :relief,      type: :relief     # flat, raised, sunken, groove, ridge, solid
  option :text,        type: :string
  option :underline,   type: :integer    # index of character to underline
  option :wraplength,  type: :pixels     # max line length before wrapping

  # Widget-specific options
  option :height,     type: :integer    # height in lines of text
  option :state,      type: :string     # normal, active, disabled
  option :width,      type: :integer    # width in characters
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
