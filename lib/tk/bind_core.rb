# frozen_string_literal: true
#
# tk/bind_core.rb - Mixin for event binding on Tk objects
#
# Provides bind, bind_append, bind_remove, bindinfo methods.
# Included by TkWindow, extended by Tk module, included by TkBindTag.

module TkBindCore
  def bind(context, *args, &block)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    Tk.bind(self, context, cmd, *args)
  end

  def bind_append(context, *args, &block)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    Tk.bind_append(self, context, cmd, *args)
  end

  def bind_remove(context)
    Tk.bind_remove(self, context)
  end

  def bindinfo(context = nil)
    Tk.bindinfo(self, context)
  end
end
