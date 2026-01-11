# frozen_string_literal: false
#
# tk/xim.rb : control input_method
#
require 'tk' unless defined?(Tk)

module TkXIM
  include Tk
  extend Tk

  TkCommandNames = ['imconfigure'.freeze].freeze

  def TkXIM.useinputmethods(value = None, win = nil)
    if value == None
      if win
        bool(tk_call_without_enc('tk', 'useinputmethods',
                                 '-displayof', win))
      else
        bool(tk_call_without_enc('tk', 'useinputmethods'))
      end
    else
      if win
        bool(tk_call_without_enc('tk', 'useinputmethods',
                                 '-displayof', win, value))
      else
        bool(tk_call_without_enc('tk', 'useinputmethods', value))
      end
    end
  end

  def TkXIM.useinputmethods_displayof(win, value = None)
    TkXIM.useinputmethods(value, win)
  end

  def TkXIM.caret(win, keys=nil)
    if keys
      tk_call_without_enc('tk', 'caret', win, *hash_kv(keys))
      self
    else
      lst = tk_split_list(tk_call_without_enc('tk', 'caret', win))
      info = {}
      while key = lst.shift
        info[key[1..-1]] = lst.shift
      end
      info
    end
  end

  # imconfigure was specific to Japanized Tcl/Tk and no longer exists
  def TkXIM.configure(win, slot, value=None)
    # no-op - imconfigure command not available in standard Tcl/Tk
  end

  def TkXIM.configinfo(win, slot=nil)
    if TkComm::GET_CONFIGINFOwoRES_AS_ARRAY
      []
    else
      TkXIM.current_configinfo(win, slot)
    end
  end

  def TkXIM.current_configinfo(win, slot=nil)
    {}
  end

  def useinputmethods(value=None)
    TkXIM.useinputmethods(value, self)
  end

  def caret(keys=nil)
    TkXIM.caret(self, keys=nil)
  end

  def imconfigure(slot, value=None)
    TkXIM.configure(self, slot, value)
  end

  def imconfiginfo(slot=nil)
    TkXIM.configinfo(self, slot)
  end
end
