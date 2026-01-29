# frozen_string_literal: false
#
# tk/scale.rb : treat scale widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/scale.html
#
require 'tk/option_dsl'

class Tk::Scale<TkWindow
  include Tk::Generated::Scale
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :activebackground
  #   :background
  #   :bigincrement
  #   :borderwidth
  #   :command (callback)
  #   :cursor
  #   :digits
  #   :font
  #   :foreground
  #   :from
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :label
  #   :length
  #   :orient
  #   :relief
  #   :repeatdelay
  #   :repeatinterval
  #   :resolution
  #   :showvalue
  #   :sliderlength
  #   :sliderrelief
  #   :state
  #   :takefocus
  #   :tickinterval
  #   :to
  #   :troughcolor
  #   :variable (tkvariable)
  #   :width
  # @generated:options:end



  TkCommandNames = ['scale'.freeze].freeze
  WidgetClassName = 'Scale'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def create_self(keys)
    if keys and keys != None
      if keys.key?('command') && ! keys['command'].kind_of?(String)
        cmd = keys.delete('command')
        keys['command'] = proc{|val| cmd.call(val.to_f)}
      end
      tk_call_without_enc(self.class::TkCommandNames[0], @path,
                          *hash_kv(keys, true))
    else
      tk_call_without_enc(self.class::TkCommandNames[0], @path)
    end
  end
  private :create_self

  # NOTE: __strval_optkeys override for 'label' removed - now declared via OptionDSL

  def _wrap_command_arg(cmd)
    proc{|val|
      if val.kind_of?(String)
        cmd.call(number(val))
      else
        cmd.call(val)
      end
    }
  end
  private :_wrap_command_arg

  def configure_cmd(slot, value)
    configure(slot=>value)
  end

  def configure(slot, value=None)
    if (slot == 'command' || slot == :command)
      configure('command'=>value)
    elsif slot.kind_of?(Hash) &&
        (slot.key?('command') || slot.key?(:command))
      slot = _symbolkey2str(slot)
      slot['command'] = _wrap_command_arg(slot.delete('command'))
    end
    super(slot, value)
  end

  def command(cmd=nil, &block)
    configure('command'=>cmd || block)
  end

  def get(x=None, y=None)
    number(tk_send_without_enc('get', x, y))
  end

  def coords(val=None)
    tk_split_list(tk_send_without_enc('coords', val))
  end

  def identify(x, y)
    tk_send_without_enc('identify', x, y)
  end

  def set(val)
    tk_send_without_enc('set', val)
  end

  def value
    get
  end

  def value=(val)
    set(val)
    val
  end
end

#TkScale = Tk::Scale unless Object.const_defined? :TkScale
#Tk.__set_toplevel_aliases__(:Tk, Tk::Scale, :TkScale)
Tk.__set_loaded_toplevel_aliases__('tk/scale.rb', :Tk, Tk::Scale, :TkScale)
