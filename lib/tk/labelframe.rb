# frozen_string_literal: false
#
# tk/labelframe.rb : treat labelframe widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/labelframe.html
#
require 'tk' unless defined?(Tk)
require 'tk/frame'

class Tk::LabelFrame<Tk::Frame
  TkCommandNames = ['labelframe'.freeze].freeze
  WidgetClassName = 'Labelframe'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # LabelFrame-specific options (inherits from Tk::Frame)
  option :font,         type: :string
  option :foreground,   type: :color, aliases: [:fg]
  option :labelanchor,  type: :string    # nw, n, ne, en, e, es, se, s, sw, ws, w, wn
  option :labelwidget,  type: :string    # widget path
  option :text,         type: :string
  #def create_self(keys)
  #  if keys and keys != None
  #    tk_call_without_enc('labelframe', @path, *hash_kv(keys, true))
  #  else
  #    tk_call_without_enc('labelframe', @path)
  #  end
  #end
  #private :create_self

  def __val2ruby_optkeys  # { key=>proc, ... }
    super().update('labelwidget'=>proc{|v| window(v)})
  end
  private :__val2ruby_optkeys
end

Tk::Labelframe = Tk::LabelFrame
#TkLabelFrame = Tk::LabelFrame unless Object.const_defined? :TkLabelFrame
#TkLabelframe = Tk::Labelframe unless Object.const_defined? :TkLabelframe
#Tk.__set_toplevel_aliases__(:Tk, Tk::LabelFrame, :TkLabelFrame, :TkLabelframe)
Tk.__set_loaded_toplevel_aliases__('tk/labelframe.rb', :Tk, Tk::LabelFrame,
                                   :TkLabelFrame, :TkLabelframe)
