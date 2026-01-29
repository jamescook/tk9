# frozen_string_literal: false
#
# tk/message.rb : treat message widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/message.html
#
require 'tk/label'

class Tk::Message<Tk::Label
  include Tk::Generated::Message
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :anchor
  #   :aspect
  #   :background
  #   :borderwidth
  #   :cursor
  #   :font
  #   :foreground
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :justify
  #   :padx
  #   :pady
  #   :relief
  #   :takefocus
  #   :text
  #   :textvariable (tkvariable)
  #   :width
  # @generated:options:end


  TkCommandNames = ['message'.freeze].freeze
  WidgetClassName = 'Message'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  #def create_self(keys)
  #  if keys and keys != None
  #    tk_call_without_enc('message', @path, *hash_kv(keys, true))
  #  else
  #    tk_call_without_enc('message', @path)
  #  end
  #end
  private :create_self
end

#TkMessage = Tk::Message unless Object.const_defined? :TkMessage
#Tk.__set_toplevel_aliases__(:Tk, Tk::Message, :TkMessage)
Tk.__set_loaded_toplevel_aliases__('tk/message.rb', :Tk, Tk::Message,
                                   :TkMessage)
