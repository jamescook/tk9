# frozen_string_literal: true

require_relative 'tk/util'    # TkUtil
require_relative 'tk/event'   # TkEvent

module TkComm
  include TkUtil
  extend TkUtil

  include TkEvent
  extend TkEvent

  WidgetClassNames = {}
  TkExtlibAutoloadModule = []

  # None = Object.new  ### --> definition is moved to TkUtil module
  # def None.to_s
  #   'None'
  # end
  # None.freeze

  #Tk_CMDTBL = {}
  #Tk_WINDOWS = {}
  Tk_IDs = [
    String.new("00000"), # [0]-cmdid - mutable for succ!
    String.new("00000")  # [1]-winid - mutable for succ!
  ]
  Tk_IDs.instance_eval{
    @mutex = Mutex.new
    def mutex; @mutex; end
    freeze
  }

  # for backward compatibility
  Tk_CMDTBL = Object.new
  def Tk_CMDTBL.method_missing(id, *args)
    TkCore::INTERP.tk_cmd_tbl.__send__(id, *args)
  end
  Tk_CMDTBL.freeze
  Tk_WINDOWS = Object.new
  def Tk_WINDOWS.method_missing(id, *args)
    TkCore::INTERP.tk_windows.__send__(id, *args)
  end
  Tk_WINDOWS.freeze

  self.instance_eval{
    @cmdtbl = []
  }

  unless const_defined?(:GET_CONFIGINFO_AS_ARRAY)
    # GET_CONFIGINFO_AS_ARRAY = false => returns a Hash { opt =>val, ... }
    #                           true  => returns an Array [[opt,val], ... ]
    # val is a list which includes resource info.
    GET_CONFIGINFO_AS_ARRAY = true
  end
  unless const_defined?(:GET_CONFIGINFOwoRES_AS_ARRAY)
    # for configinfo without resource info; list of [opt, value] pair
    #           false => returns a Hash { opt=>val, ... }
    #           true  => returns an Array [[opt,val], ... ]
    GET_CONFIGINFOwoRES_AS_ARRAY = true
  end
  #  *** ATTENTION ***
  # 'current_configinfo' method always returns a Hash under all cases of above.

  def error_at
    frames = caller()
    frames.delete_if do |c|
      c =~ %r!/tk(|core|thcore|canvas|text|entry|scrollbox)\.rb:\d+!
    end
    frames
  end
  private :error_at

  def _genobj_for_tkwidget(path)
    return TkRoot.new if path == '.'

    begin
      #tk_class = TkCore::INTERP._invoke('winfo', 'class', path)
      tk_class = Tk.ip_invoke_without_enc('winfo', 'class', path)
    rescue
      return path
    end

    if ruby_class = WidgetClassNames[tk_class]
      ruby_class_name = ruby_class.name
      # gen_class_name = ruby_class_name + 'GeneratedOnTk'
      gen_class_name = ruby_class_name
      classname_def = ''
    else # ruby_class == nil
      if Tk.const_defined?(tk_class)
        Tk.const_get(tk_class)  # auto_load
        ruby_class = WidgetClassNames[tk_class]
      end

      unless ruby_class
        mods = TkExtlibAutoloadModule.find_all{|m| m.const_defined?(tk_class)}
        mods.each{|mod|
          begin
            mod.const_get(tk_class)  # auto_load
            break if (ruby_class = WidgetClassNames[tk_class])
          rescue LoadError
            # ignore load error
          end
        }
      end

      unless ruby_class
        std_class = 'Tk' << tk_class
        if Object.const_defined?(std_class)
          Object.const_get(std_class)  # auto_load
          ruby_class = WidgetClassNames[tk_class]
        end
      end

      unless ruby_class
        if Tk.const_defined?('TOPLEVEL_ALIASES') &&
            Tk::TOPLEVEL_ALIASES.const_defined?(std_class)
          Tk::TOPLEVEL_ALIASES.const_get(std_class)  # auto_load
          ruby_class = WidgetClassNames[tk_class]
        end
      end

      if ruby_class
        # found
        ruby_class_name = ruby_class.name
        gen_class_name = ruby_class_name
        classname_def = ''
      else
        # unknown
        ruby_class_name = 'TkWindow'
        gen_class_name = 'TkWidget_' + tk_class
        classname_def = "WidgetClassName = '#{tk_class}'.freeze"
      end
    end

    base = Object
    gen_class_name.split('::').each{|klass|
      next if klass == ''
      if base.const_defined?(klass)
        base = base.class_eval klass
      else
        base = base.class_eval "class #{klass}<#{ruby_class_name}
                                  #{classname_def}
                                end
                                #{klass}"
      end
    }
    base.class_eval "#{gen_class_name}.new('widgetname'=>'#{path}',
                                           'without_creating'=>true)"
  end
  private :_genobj_for_tkwidget
  module_function :_genobj_for_tkwidget

  def _at(x,y=nil)
    if y
      "@#{Integer(x)},#{Integer(y)}"
    else
      "@#{Integer(x)}"
    end
  end
  module_function :_at

  # Pre-compiled patterns for tk_tcl2ruby
  CALLBACK_PATTERN = /rb_out\S*(?:\s+(::\S*|\{(::.*)\}|"(::.*)"))?[ ](c(?:_\d+_)?\d+)/.freeze
  IMAGE_PATTERN = /\Ai(?:_\d+_)?\d+\z/.freeze
  FLOAT_PATTERN = /\A-?\d+\.?\d*(?:e[-+]?\d+)?\z/.freeze
  ESCAPED_SPACE_PATTERN = /\\ /.freeze

  # Convert Tcl string values to appropriate Ruby objects.
  # Uses start_with?, character checks to minimize regex operations.
  #
  # NOTE: Number parsing here overlaps with TkUtil.number/num_or_str.
  # Future refactor could consolidate, but TkUtil handles hex/octal (0x/0o)
  # while this uses regex for decimal only. Tcl returns values in decimal
  # form (hex/octal are input formats), so decimal-only should suffice.
  # https://wiki.tcl-lang.org/page/What+kinds+of+numbers+does+Tcl+recognize
  def tk_tcl2ruby(val, enc_mode = false, listobj = true)
    return val if val.empty?

    first_char = val.getbyte(0)

    # Callback reference: "rb_out ... c12345"
    if first_char == 114 && val.start_with?('rb_out') # 'r'
      if (m = CALLBACK_PATTERN.match(val))
        return TkCore::INTERP.tk_cmd_tbl[m[4]]
      end
    end

    # Font: "@fontXXX"
    if first_char == 64 && val.start_with?('@font') # '@'
      return TkFont.get_obj(val)
    end

    # Widget path: "." or ".something" (but not ".5" which is a float)
    if first_char == 46 # '.'
      second_char = val.getbyte(1)
      # Valid if: no second char (root ".") OR second char is not a digit
      if second_char.nil? || second_char < 48 || second_char > 57
        win = TkCore::INTERP.tk_windows[val]
        return win ? win : _genobj_for_tkwidget(val)
      end
    end

    # Image: "i12345" or "i_1_999"
    if first_char == 105 # 'i'
      second_char = val.getbyte(1)
      if second_char && (second_char == 95 || (second_char >= 48 && second_char <= 57)) # '_' or digit
        if IMAGE_PATTERN.match?(val)
          return TkImage::Tk_IMGTBL.mutex.synchronize {
            TkImage::Tk_IMGTBL[val] || val
          }
        end
      end
    end

    # Check for spaces (list or escaped)
    if val.include?(' ')
      if val.include?('\ ')
        # Escaped spaces - unescape them
        return val.gsub(ESCAPED_SPACE_PATTERN, ' ')
      elsif listobj
        # Unescaped space = Tcl list, parse recursively
        val = _toUTF8(val) unless enc_mode
        return tk_split_escstr(val, false, false).collect { |elt|
          tk_tcl2ruby(elt, true, listobj)
        }
      elsif enc_mode
        return _fromUTF8(val)
      else
        return val
      end
    end

    # Try integer (most common numeric case)
    # Only if starts with digit or minus followed by digit
    if (first_char >= 48 && first_char <= 57) || # '0'-'9'
       (first_char == 45 && val.length > 1) # '-' and more chars
      # Quick check: all digits (or leading minus)?
      if val.match?(/\A-?\d+\z/)
        return val.to_i
      end
      # Try float
      if FLOAT_PATTERN.match?(val)
        return val.to_f
      end
    end

    # Default: return as string, possibly with encoding conversion
    enc_mode ? _fromUTF8(val) : val
  end

  private :tk_tcl2ruby
  module_function :tk_tcl2ruby

  # List parsing/merging functions using Tcl's native C implementation.
  # These are faster than pure Ruby for merge operations with special chars.

  def tk_split_escstr(str, src_enc=true, dst_enc=true)
    str = _toUTF8(str) if src_enc
    if dst_enc
      TkCore::INTERP._split_tklist(str).map!{|s| _fromUTF8(s)}
    else
      TkCore::INTERP._split_tklist(str)
    end
  end

  def tk_split_sublist(str, depth=-1, src_enc=true, dst_enc=true)
    # return [] if str == ""
    # list = TkCore::INTERP._split_tklist(str)
    str = _toUTF8(str) if src_enc

    if depth == 0
      return "" if str == ""
      list = [str]
    else
      return [] if str == ""
      list = TkCore::INTERP._split_tklist(str)
    end
    if list.size == 1
      # tk_tcl2ruby(list[0], nil, false)
      tk_tcl2ruby(list[0], dst_enc, false)
    else
      list.collect{|token| tk_split_sublist(token, depth - 1, false, dst_enc)}
    end
  end

  def tk_split_list(str, depth=0, src_enc=true, dst_enc=true)
    return [] if str == ""
    str = _toUTF8(str) if src_enc
    TkCore::INTERP._split_tklist(str).map!{|token|
      tk_split_sublist(token, depth - 1, false, dst_enc)
    }
  end

  def tk_split_simplelist(str, src_enc=true, dst_enc=true)
    #lst = TkCore::INTERP._split_tklist(str)
    #if (lst.size == 1 && lst =~ /^\{.*\}$/)
    #  TkCore::INTERP._split_tklist(str[1..-2])
    #else
    #  lst
    #end

    str = _toUTF8(str) if src_enc
    if dst_enc
      TkCore::INTERP._split_tklist(str).map!{|s| _fromUTF8(s)}
    else
      TkCore::INTERP._split_tklist(str)
    end
  end

  def array2tk_list(ary, enc=nil)
    return "" if ary.size == 0

    sys_enc = TkCore::INTERP.encoding
    sys_enc = TclTkLib.encoding_system unless sys_enc

    dst_enc = (enc == nil)? sys_enc: enc

    dst = ary.collect{|e|
      if e.kind_of? Array
        s = array2tk_list(e, enc)
      elsif e.kind_of? Hash
        tmp_ary = []
        #e.each{|k,v| tmp_ary << k << v }
        e.each{|k,v| tmp_ary << "-#{_get_eval_string(k)}" << v }
        s = array2tk_list(tmp_ary, enc)
      else
        s = _get_eval_string(e, enc)
      end

      if dst_enc != true && dst_enc != false
        s_enc = s.encoding.name
        dst_enc = true if s_enc != dst_enc
      end

      s
    }

    if sys_enc && dst_enc
      dst.map!{|s| _toUTF8(s)}
      ret = TkCore::INTERP._merge_tklist(*dst)
      if dst_enc.kind_of?(String)
        ret = _fromUTF8(ret, dst_enc)
        ret.force_encoding(dst_enc)
      else
        ret.force_encoding('utf-8')
      end
      ret
    else
      TkCore::INTERP._merge_tklist(*dst)
    end
  end

  private :tk_split_escstr, :tk_split_sublist
  private :tk_split_list, :tk_split_simplelist
  private :array2tk_list

  module_function :tk_split_escstr, :tk_split_sublist
  module_function :tk_split_list, :tk_split_simplelist
  module_function :array2tk_list

  private_class_method :tk_split_escstr, :tk_split_sublist
  private_class_method :tk_split_list, :tk_split_simplelist
#  private_class_method :array2tk_list

  def list(val, depth=0, enc=true)
    tk_split_list(val, depth, enc, enc)
  end
  def simplelist(val, src_enc=true, dst_enc=true)
    tk_split_simplelist(val, src_enc, dst_enc)
  end
  def window(val)
    if val =~ /^\./
      #Tk_WINDOWS[val]? Tk_WINDOWS[val] : _genobj_for_tkwidget(val)
      TkCore::INTERP.tk_windows[val]?
           TkCore::INTERP.tk_windows[val] : _genobj_for_tkwidget(val)
    else
      nil
    end
  end
  def image_obj(val)
    if val =~ /^i(_\d+_)?\d+$/
      TkImage::Tk_IMGTBL.mutex.synchronize{
        TkImage::Tk_IMGTBL[val]? TkImage::Tk_IMGTBL[val] : val
      }
    else
      val
    end
  end
  def procedure(val)
    if val =~ /rb_out\S*(?:\s+(::\S*|[{](::.*)[}]|["](::.*)["]))? (c(_\d+_)?(\d+))/
      return TkCore::INTERP.tk_cmd_tbl[$4].cmd
    else
      #nil
      val
    end
  end
  private :bool, :number, :num_or_str, :num_or_nil, :string
  private :list, :simplelist, :window, :image_obj, :procedure
  module_function :bool, :number, :num_or_str, :num_or_nil, :string
  module_function :list, :simplelist, :window, :image_obj, :procedure

  def slice_ary(ary, size, &b)
    if b
      ary.each_slice(size, &b)
    else
      ary.each_slice(size).to_a
    end
  end
  private :slice_ary
  module_function :slice_ary

  def subst(str, *opts)
    # opts := :nobackslashes | :nocommands | novariables
    tk_call('subst',
            *(opts.collect{|opt|
                opt = opt.to_s
                (opt[0] == ?-)? opt: '-' << opt
              } << str))
  end

  def _toUTF8(str, encoding = nil)
    TkCore::INTERP._toUTF8(str, encoding)
  end
  def _fromUTF8(str, encoding = nil)
    TkCore::INTERP._fromUTF8(str, encoding)
  end
  private :_toUTF8, :_fromUTF8
  module_function :_toUTF8, :_fromUTF8

  def _callback_entry_class?(cls)
    cls <= Proc || cls <= Method || cls <= TkCallbackEntry
  end
  private :_callback_entry_class?
  module_function :_callback_entry_class?

  def _callback_entry?(obj)
    obj.kind_of?(Proc) || obj.kind_of?(Method) || obj.kind_of?(TkCallbackEntry)
  end
  private :_callback_entry?
  module_function :_callback_entry?

  def _curr_cmd_id
    #id = format("c%.4d", Tk_IDs[0])
    "c" + TkCore::INTERP._ip_id_ + TkComm::Tk_IDs[0]
  end
  def _next_cmd_id
    TkComm::Tk_IDs.mutex.synchronize{
      id = _curr_cmd_id
      #Tk_IDs[0] += 1
      TkComm::Tk_IDs[0].succ!
      id
    }
  end
  private :_curr_cmd_id, :_next_cmd_id
  module_function :_curr_cmd_id, :_next_cmd_id

  # Register a Ruby proc/block as a Tcl callback.
  #
  # Returns a Tcl command string like "rb_out <ip_id> <callback_id>" that
  # Tcl can invoke. When Tcl calls this command, it triggers:
  #   Tcl rb_out -> C ruby_callback -> TkCore.callback -> tk_cmd_tbl[id].call
  #
  # The callback is stored in TkCore::INTERP.tk_cmd_tbl (per-interpreter).
  # Use uninstall_cmd to remove when the callback is no longer needed.
  def TkComm.install_cmd(cmd, local_cmdtbl=nil)
    return '' if cmd == ''
    begin
      ns = TkCore::INTERP._invoke_without_enc('namespace', 'current')
      ns = nil if ns == '::' # for backward compatibility
    rescue
      # probably, Tcl7.6
      ns = nil
    end
    id = _next_cmd_id
    #Tk_CMDTBL[id] = cmd
    if cmd.kind_of?(TkCallbackEntry)
      TkCore::INTERP.tk_cmd_tbl[id] = cmd
    else
      TkCore::INTERP.tk_cmd_tbl[id] = TkCore::INTERP.get_cb_entry(cmd)
    end
    @cmdtbl = [] unless defined? @cmdtbl
    @cmdtbl.push id

    if local_cmdtbl && local_cmdtbl.kind_of?(Array)
      begin
        local_cmdtbl << id
      rescue Exception
        # ignore
      end
    end

    #return Kernel.format("rb_out %s", id);
    if ns
      "rb_out#{TkCore::INTERP._ip_id_} #{ns} #{id}"
    else
      "rb_out#{TkCore::INTERP._ip_id_} #{id}"
    end
  end
  # Remove a previously registered callback from tk_cmd_tbl.
  # Pass the same ID string returned by install_cmd.
  def TkComm.uninstall_cmd(id, local_cmdtbl=nil)
    id = $4 if id =~ /rb_out\S*(?:\s+(::\S*|[{](::.*)[}]|["](::.*)["]))? (c(_\d+_)?(\d+))/

    if local_cmdtbl && local_cmdtbl.kind_of?(Array)
      begin
        local_cmdtbl.delete(id)
      rescue Exception
        # ignore
      end
    end
    @cmdtbl.delete(id)

    #Tk_CMDTBL.delete(id)
    TkCore::INTERP.tk_cmd_tbl.delete(id)
  end
  # private :install_cmd, :uninstall_cmd
  # module_function :install_cmd, :uninstall_cmd
  def install_cmd(cmd)
    TkComm.install_cmd(cmd, @cmdtbl)
  end
  def uninstall_cmd(id)
    TkComm.uninstall_cmd(id, @cmdtbl)
  end

  def install_win(ppath,name=nil)
    if name
      if name == ''
        raise ArgumentError, "invalid widget-name '#{name}'"
      end
      if name[0] == ?.
        @path = '' + name
        @path.freeze
        return TkCore::INTERP.tk_windows[@path] = self
      end
    else
      Tk_IDs.mutex.synchronize{
        name = "w" + TkCore::INTERP._ip_id_ + Tk_IDs[1]
        Tk_IDs[1].succ!
      }
    end
    if !ppath or ppath == '.'
      @path = '.' + name
    else
      @path = ppath + '.' + name
    end
    @path.freeze
    TkCore::INTERP.tk_windows[@path] = self
  end

  def uninstall_win()
    #Tk_WINDOWS.delete(@path)
    TkCore::INTERP.tk_windows.delete(@path)
  end
  private :install_win, :uninstall_win

  def _epath(win)
    if win.kind_of?(TkObject)
      win.epath
    elsif win.respond_to?(:epath)
      win.epath
    else
      win
    end
  end
  private :_epath

  def tk_event_sequence(context)
    if context.kind_of? TkVirtualEvent
      context = context.path
    end
    if context.kind_of? Array
      context = context.collect{|ev|
        if ev.kind_of? TkVirtualEvent
          ev.path
        else
          ev
        end
      }.join("><")
    end
    if /,/ =~ context
      context = context.split(/\s*,\s*/).join("><")
    else
      context
    end
  end

  def _bind_core(mode, what, context, cmd, *args)
    id = install_bind(cmd, *args) if cmd
    begin
      tk_call_without_enc(*(what + ["<#{tk_event_sequence(context)}>",
                              mode + id]))
    rescue
      uninstall_cmd(id) if cmd
      fail
    end
  end

  def _bind(what, context, cmd, *args)
    _bind_core('', what, context, cmd, *args)
  end

  def _bind_append(what, context, cmd, *args)
    _bind_core('+', what, context, cmd, *args)
  end

  def _bind_remove(what, context)
    tk_call_without_enc(*(what + ["<#{tk_event_sequence(context)}>", '']))
  end

  def _bindinfo(what, context=nil)
    if context
      tk_call_without_enc(*what+["<#{tk_event_sequence(context)}>"]).each_line.collect {|cmdline|
=begin
        if cmdline =~ /^rb_out\S* (c(?:_\d+_)?\d+)\s+(.*)$/
          #[Tk_CMDTBL[$1], $2]
          [TkCore::INTERP.tk_cmd_tbl[$1], $2]
=end
        if cmdline =~ /rb_out\S*(?:\s+(::\S*|[{](::.*)[}]|["](::.*)["]))? (c(_\d+_)?(\d+))/
          [TkCore::INTERP.tk_cmd_tbl[$4], $5]
        else
          cmdline
        end
      }
    else
      tk_split_simplelist(tk_call_without_enc(*what)).collect!{|seq|
        l = seq.scan(/<*[^<>]+>*/).collect!{|subseq|
          case (subseq)
          when /^<<[^<>]+>>$/
            TkVirtualEvent.getobj(subseq[1..-2])
          when /^<[^<>]+>$/
            subseq[1..-2]
          else
            subseq.split('')
          end
        }.flatten
        (l.size == 1) ? l[0] : l
      }
    end
  end

  def _bind_core_for_event_class(klass, mode, what, context, cmd, *args)
    id = install_bind_for_event_class(klass, cmd, *args) if cmd
    begin
      tk_call_without_enc(*(what + ["<#{tk_event_sequence(context)}>",
                              mode + id]))
    rescue
      uninstall_cmd(id) if cmd
      fail
    end
  end

  def _bind_for_event_class(klass, what, context, cmd, *args)
    _bind_core_for_event_class(klass, '', what, context, cmd, *args)
  end

  def _bind_append_for_event_class(klass, what, context, cmd, *args)
    _bind_core_for_event_class(klass, '+', what, context, cmd, *args)
  end

  def _bind_remove_for_event_class(klass, what, context)
    _bind_remove(what, context)
  end

  def _bindinfo_for_event_class(klass, what, context=nil)
    _bindinfo(what, context)
  end

  private :tk_event_sequence
  private :_bind_core, :_bind, :_bind_append, :_bind_remove, :_bindinfo
  private :_bind_core_for_event_class, :_bind_for_event_class,
          :_bind_append_for_event_class, :_bind_remove_for_event_class,
          :_bindinfo_for_event_class

  def bind(tagOrClass, context, *args, &block)
    # if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind(["bind", tagOrClass], context, cmd, *args)
    tagOrClass
  end

  def bind_append(tagOrClass, context, *args, &block)
    # if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind_append(["bind", tagOrClass], context, cmd, *args)
    tagOrClass
  end

  def bind_remove(tagOrClass, context)
    _bind_remove(['bind', tagOrClass], context)
    tagOrClass
  end

  def bindinfo(tagOrClass, context=nil)
    _bindinfo(['bind', tagOrClass], context)
  end

  def bind_all(context, *args, &block)
    # if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind(['bind', 'all'], context, cmd, *args)
    TkBindTag::ALL
  end

  def bind_append_all(context, *args, &block)
    # if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind_append(['bind', 'all'], context, cmd, *args)
    TkBindTag::ALL
  end

  def bind_remove_all(context)
    _bind_remove(['bind', 'all'], context)
    TkBindTag::ALL
  end

  def bindinfo_all(context=nil)
    _bindinfo(['bind', 'all'], context)
  end
end
