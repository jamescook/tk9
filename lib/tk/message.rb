# frozen_string_literal: false
#
# tk/message.rb : treat message widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/message.html
#
require 'tk' unless defined?(Tk)
require 'tk/label'

class Tk::Message<Tk::Label
  TkCommandNames = ['message'.freeze].freeze
  WidgetClassName = 'Message'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Message-specific options (inherits from Tk::Label)
  option :aspect, type: :integer
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
