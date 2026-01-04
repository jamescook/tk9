# frozen_string_literal: true

class TkObject<TkKernel
  extend  TkCore
  include Tk
  include TkConfigMethod
  include TkBindCore

  # Returns the Tk widget path (e.g., ".frame1.button2")
  # Used by Tcl/Tk commands to identify this widget
  def path
    @path
  end

  # Escaped path - currently same as path
  # Historical: was used for paths needing escape sequences
  def epath
    @path
  end

  def to_eval
    @path
  end

  def tk_send(cmd, *rest)
    tk_call(path, cmd, *rest)
  end
  def tk_send_without_enc(cmd, *rest)
    tk_call_without_enc(path, cmd, *rest)
  end
  def tk_send_with_enc(cmd, *rest)
    tk_call_with_enc(path, cmd, *rest)
  end
  # private :tk_send, :tk_send_without_enc, :tk_send_with_enc

  def tk_send_to_list(cmd, *rest)
    tk_call_to_list(path, cmd, *rest)
  end
  def tk_send_to_list_without_enc(cmd, *rest)
    tk_call_to_list_without_enc(path, cmd, *rest)
  end
  def tk_send_to_list_with_enc(cmd, *rest)
    tk_call_to_list_with_enc(path, cmd, *rest)
  end
  def tk_send_to_simplelist(cmd, *rest)
    tk_call_to_simplelist(path, cmd, *rest)
  end
  def tk_send_to_simplelist_without_enc(cmd, *rest)
    tk_call_to_simplelist_without_enc(path, cmd, *rest)
  end
  def tk_send_to_simplelist_with_enc(cmd, *rest)
    tk_call_to_simplelist_with_enc(path, cmd, *rest)
  end

  def method_missing(id, *args)
    name = id.id2name
    case args.length
    when 1
      if name[-1] == ?=
        configure name[0..-2], args[0]
        args[0]
      else
        configure name, args[0]
        self
      end
    when 0
      begin
        cget(name)
      rescue
        if self.kind_of?(TkWindow) && name != "to_ary" && name != "to_str"
          fail NameError,
               "unknown option '#{id}' for #{self.inspect} (deleted widget?)"
        else
          super(id, *args)
        end
#        fail NameError,
#             "undefined local variable or method `#{name}' for #{self.to_s}",
#             error_at
      end
    else
      super(id, *args)
#      fail NameError, "undefined method `#{name}' for #{self.to_s}", error_at
    end
  end

  def event_generate(context, keys=nil)
    if context.kind_of?(TkEvent::Event)
      context.generate(self, ((keys)? keys: {}))
    elsif keys
      #tk_call('event', 'generate', path,
      #       "<#{tk_event_sequence(context)}>", *hash_kv(keys))
      tk_call_without_enc('event', 'generate', path,
                          "<#{tk_event_sequence(context)}>",
                          *hash_kv(keys, true))
    else
      #tk_call('event', 'generate', path, "<#{tk_event_sequence(context)}>")
      tk_call_without_enc('event', 'generate', path,
                          "<#{tk_event_sequence(context)}>")
    end
  end

  def tk_trace_variable(v)
    #unless v.kind_of?(TkVariable)
    #  fail(ArgumentError, "type error (#{v.class}); must be TkVariable object")
    #end
    v
  end
  private :tk_trace_variable

  def destroy
    #tk_call 'trace', 'vdelete', @tk_vn, 'w', @var_id if @var_id
  end
end

