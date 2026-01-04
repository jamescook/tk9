# frozen_string_literal: false

require_relative 'tk/tk_callback_entry'  # TkCallbackEntry

module TkCore
  include TkComm
  extend TkComm

  WITH_RUBY_VM  = Object.const_defined?(:RubyVM) && ::RubyVM.class == Class
  WITH_ENCODING = defined?(::Encoding.default_external) && true
  #WITH_ENCODING = Object.const_defined?(:Encoding) && ::Encoding.class == Class

  unless self.const_defined? :INTERP
    if self.const_defined? :IP_NAME
      name = IP_NAME.to_s
    else
      #name = nil
      name = $0
    end
    if self.const_defined? :IP_OPTS
      if IP_OPTS.kind_of?(Hash)
        opts = hash_kv(IP_OPTS).join(' ')
      else
        opts = IP_OPTS.to_s
      end
    else
      opts = ''
    end

    # Tk requires the main thread for UI operations.
    # On macOS this is enforced by AppKit; on other platforms it simplifies
    # the threading model and avoids complex synchronization issues.
    if Thread.current != Thread.main
      raise RuntimeError,
        "Tk requires the main thread. " \
        "IRB and other REPLs that evaluate code in background threads are not supported. " \
        "Run your Tk code in a script instead."
    end
    INTERP = TclTkIp.new(name, opts) unless self.const_defined? :INTERP

    def INTERP.__getip
      self
    end
    def INTERP.default_master?
      true
    end

    # Per-interpreter tables for callbacks and widget tracking
    INTERP.instance_eval{
      # tk_cmd_tbl: Maps callback IDs (e.g., "c00001") to Ruby procs.
      # Populated by TkComm.install_cmd, invoked by TkCore.callback.
      # This is the central callback registry for this interpreter.
      @tk_cmd_tbl =
        Hash.new{|hash, key|
                         fail IndexError, "unknown command ID '#{key}'"
                       }
      def @tk_cmd_tbl.[]=(idx,val)
        if self.has_key?(idx) && Thread.current.group != ThreadGroup::Default
          fail SecurityError,"cannot change the entried command"
        end
        super(idx,val)
      end

      @tk_windows = {}

      @tk_table_list = []

      @init_ip_env  = []  # table of Procs
      @add_tk_procs = []  # table of [name, args, body]

      @force_default_encoding ||= [false]
      unless @encoding
        @encoding = [nil]
        def @encoding.to_s; self.join(nil); end
      end

      @cb_entry_class = Class.new(TkCallbackEntry){
        class << self
          def inspect
            sprintf("#<Class(TkCallbackEntry):%0x>", self.__id__)
          end
          alias to_s inspect
        end

        def initialize(ip, cmd)
          @ip = ip
          @cmd = cmd
        end
        attr_reader :ip, :cmd
        def call(*args)
          @ip.cb_eval(@cmd, *args)
        end
        def inspect
          sprintf("#<cb_entry:%0x>", self.__id__)
        end
        alias to_s inspect
      }.freeze
    }

    def INTERP.cb_entry_class
      @cb_entry_class
    end
    def INTERP.tk_cmd_tbl
      @tk_cmd_tbl
    end
    def INTERP.tk_windows
      @tk_windows
    end

    class Tk_OBJECT_TABLE
      def initialize(id)
        @id = id
        @mutex = Mutex.new
      end
      def mutex
        @mutex
      end
      def method_missing(m, *args, &b)
        TkCore::INTERP.tk_object_table(@id).__send__(m, *args, &b)
      end
    end

    def INTERP.tk_object_table(id)
      @tk_table_list[id]
    end
    def INTERP.create_table
      id = @tk_table_list.size
      @tk_table_list << {}
      Tk_OBJECT_TABLE.new(id)
    end

    def INTERP.get_cb_entry(cmd)
      @cb_entry_class.new(__getip, cmd).freeze
    end
    def INTERP.cb_eval(cmd, *args)
      TkUtil._get_eval_string(TkUtil.eval_cmd(cmd, *args))
    end

    def INTERP.init_ip_env(script = (use_block = true), &block)
      script = block if use_block
      @init_ip_env << script
      script.call(self)
    end
    def INTERP.add_tk_procs(name, args = nil, body = nil)
      if name.kind_of?(Array)
        name.each{|param| self.add_tk_procs(*param)}
      else
        name = name.to_s
        @add_tk_procs << [name, args, body]
        self._invoke('proc', name, args, body) if args && body
      end
    end
    def INTERP.remove_tk_procs(*names)
      names.each{|name|
        name = name.to_s
        @add_tk_procs.delete_if{|elem|
          elem.kind_of?(Array) && elem[0].to_s == name
        }
        #self._invoke('rename', name, '')
        self.__invoke__('rename', name, '')
      }
    end
    def INTERP.init_ip_internal
      ip = self
      @init_ip_env.each{|script| script.call(ip)}
      @add_tk_procs.each{|name,args,body| ip._invoke('proc',name,args,body)}
    end
  end

  WIDGET_DESTROY_HOOK = '<WIDGET_DESTROY_HOOK>'
  INTERP._invoke_without_enc('event', 'add',
                             "<#{WIDGET_DESTROY_HOOK}>", '<Destroy>')
  INTERP._invoke_without_enc('bind', 'all', "<#{WIDGET_DESTROY_HOOK}>",
                             install_cmd(proc{|path|
                                unless TkCore::INTERP.deleted?
                                  begin
                                    if (widget=TkCore::INTERP.tk_windows[path])
                                      if widget.respond_to?(:__destroy_hook__)
                                        widget.__destroy_hook__
                                      end
                                    end
                                  rescue Exception=>e
                                      p e if $DEBUG
                                  end
                                end
                             }) << ' %W')

  INTERP.add_tk_procs(TclTkLib::FINALIZE_PROC_NAME, '',
                      "catch { bind all <#{WIDGET_DESTROY_HOOK}> {} }")

  # Register callback for TkCore.callback, used by rb_out Tcl proc
  TKCORE_CALLBACK_ID = INTERP.register_callback(proc { |*args| TkCore.callback(*args) })

  INTERP.add_tk_procs('rb_out', 'ns args', <<-EOL)
    if [regexp {^::} $ns] {
      set cmd {namespace eval $ns {ruby_callback #{TKCORE_CALLBACK_ID}} $args}
    } else {
      set cmd {eval {ruby_callback #{TKCORE_CALLBACK_ID}} $ns $args}
    }
    if {[set st [catch $cmd ret]] != 0} {
       #return -code $st $ret
       set idx [string first "\\n\\n" $ret]
       if {$idx > 0} {
          return -code $st \\
                 -errorinfo [string range $ret [expr $idx + 2] \\
                                               [string length $ret]] \\
                 [string range $ret 0 [expr $idx - 1]]
       } else {
          return -code $st $ret
       }
    } else {
        return $ret
    }
  EOL

  at_exit{ INTERP.remove_tk_procs(TclTkLib::FINALIZE_PROC_NAME) }

  EventFlag = TclTkLib::EventFlag

  def callback_break
    fail TkCallbackBreak, "Tk callback returns 'break' status"
  end

  def callback_continue
    fail TkCallbackContinue, "Tk callback returns 'continue' status"
  end

  def callback_return
    fail TkCallbackReturn, "Tk callback returns 'return' status"
  end

  # Dispatcher for Tcl->Ruby callbacks. Called by the C bridge when Tcl
  # invokes "rb_out". Looks up the callback in tk_cmd_tbl and calls it.
  # Formats exception messages with backtrace for Tcl error reporting.
  def TkCore.callback(*arg)
    begin
      if TkCore::INTERP.tk_cmd_tbl.kind_of?(Hash)
        #TkCore::INTERP.tk_cmd_tbl[arg.shift].call(*arg)
        normal_ret = false
        ret = catch(:IRB_EXIT) do  # IRB hack
          retval = TkCore::INTERP.tk_cmd_tbl[arg.shift].call(*arg)
          normal_ret = true
          retval
        end
        unless normal_ret
          # catch IRB_EXIT
          exit(ret)
        end
        ret
      end
    rescue SystemExit=>e
      exit(e.status)
    rescue Interrupt=>e
      fail(e)
    rescue Exception => e
      begin
        msg = _toUTF8(e.class.inspect) + ': ' +
              _toUTF8(e.message) + "\n" +
              "\n---< backtrace of Ruby side >-----\n" +
              _toUTF8(e.backtrace.join("\n")) +
              "\n---< backtrace of Tk side >-------"
        msg.force_encoding('utf-8')
      rescue Exception
        msg = e.class.inspect + ': ' + e.message + "\n" +
              "\n---< backtrace of Ruby side >-----\n" +
              e.backtrace.join("\n") +
              "\n---< backtrace of Tk side >-------"
      end
      # TkCore::INTERP._set_global_var('errorInfo', msg)
      # fail(e)
      fail(e, msg)
    end
  end

  def load_cmd_on_ip(tk_cmd)
    bool(tk_call('auto_load', tk_cmd))
  end

  def after(ms, cmd=nil, &block)
    cmd ||= block
    cmdid = install_cmd(proc{ret = cmd.call;uninstall_cmd(cmdid); ret})
    after_id = tk_call_without_enc("after",ms,cmdid)
    after_id.instance_variable_set('@cmdid', cmdid)
    after_id
  end

  def after_idle(cmd=nil, &block)
    cmd ||= block
    cmdid = install_cmd(proc{ret = cmd.call;uninstall_cmd(cmdid); ret})
    after_id = tk_call_without_enc('after','idle',cmdid)
    after_id.instance_variable_set('@cmdid', cmdid)
    after_id
  end

  def after_cancel(afterId)
    tk_call_without_enc('after','cancel',afterId)
    if (cmdid = afterId.instance_variable_get('@cmdid'))
      afterId.instance_variable_set('@cmdid', nil)
      uninstall_cmd(cmdid)
    end
    afterId
  end

  def windowingsystem
    tk_call_without_enc('tk', 'windowingsystem')
  end

  def scaling(scale=nil)
    if scale
      tk_call_without_enc('tk', 'scaling', scale)
    else
      Float(number(tk_call_without_enc('tk', 'scaling')))
    end
  end
  def scaling_displayof(win, scale=nil)
    if scale
      tk_call_without_enc('tk', 'scaling', '-displayof', win, scale)
    else
      Float(number(tk_call_without_enc('tk', '-displayof', win, 'scaling')))
    end
  end

  def inactive
    Integer(tk_call_without_enc('tk', 'inactive'))
  end
  def inactive_displayof(win)
    Integer(tk_call_without_enc('tk', 'inactive', '-displayof', win))
  end
  def reset_inactive
    tk_call_without_enc('tk', 'inactive', 'reset')
  end
  def reset_inactive_displayof(win)
    tk_call_without_enc('tk', 'inactive', '-displayof', win, 'reset')
  end

  def appname(name=None)
    tk_call('tk', 'appname', name)
  end

  def appsend_deny
    tk_call('rename', 'send', '')
  end

  def appsend(interp, async, *args)
    if async != true && async != false && async != nil
      args.unshift(async)
      async = false
    end
    if async
      tk_call('send', '-async', '--', interp, *args)
    else
      tk_call('send', '--', interp, *args)
    end
  end

  def rb_appsend(interp, async, *args)
    if async != true && async != false && async != nil
      args.unshift(async)
      async = false
    end
    #args = args.collect!{|c| _get_eval_string(c).gsub(/[\[\]$"]/, '\\\\\&')}
    args = args.collect!{|c| _get_eval_string(c).gsub(/[\[\]$"\\]/, '\\\\\&')}
    # args.push(').to_s"')
    # appsend(interp, async, 'ruby "(', *args)
    args.push('}.call)"')
    appsend(interp, async, 'ruby "TkComm._get_eval_string(proc{', *args)
  end

  def appsend_displayof(interp, win, async, *args)
    win = '.' if win == nil
    if async != true && async != false && async != nil
      args.unshift(async)
      async = false
    end
    if async
      tk_call('send', '-async', '-displayof', win, '--', interp, *args)
    else
      tk_call('send', '-displayor', win, '--', interp, *args)
    end
  end

  def rb_appsend_displayof(interp, win, async, *args)
    win = '.' if win == nil
    if async != true && async != false && async != nil
      args.unshift(async)
      async = false
    end
    #args = args.collect!{|c| _get_eval_string(c).gsub(/[\[\]$"]/, '\\\\\&')}
    args = args.collect!{|c| _get_eval_string(c).gsub(/[\[\]$"\\]/, '\\\\\&')}
    # args.push(').to_s"')
    # appsend_displayof(interp, win, async, 'ruby "(', *args)
    args.push('}.call)"')
    appsend(interp, win, async, 'ruby "TkComm._get_eval_string(proc{', *args)
  end

  def info(*args)
    tk_call('info', *args)
  end

  def mainloop(check_root = true)
    if Thread.current != Thread.main
      raise RuntimeError, "Tk.mainloop must be called from the main thread"
    end
    TclTkLib.mainloop(check_root)
  end

  def mainloop_thread?
    # true  : current thread is mainloop
    # nil   : there is no mainloop
    # false : mainloop is running on the other thread
    TclTkLib.mainloop_thread?
  end

  def mainloop_exist?
    TclTkLib.mainloop_thread? != nil
  end

  def is_mainloop?
    TclTkLib.mainloop_thread? == true
  end

  def mainloop_watchdog(check_root = true)
    # watchdog restarts mainloop when mainloop is dead
    TclTkLib.mainloop_watchdog(check_root)
  end

  def do_one_event(flag = TclTkLib::EventFlag::ALL)
    TclTkLib.do_one_event(flag)
  end

  def set_eventloop_tick(timer_tick)
    TclTkLib.set_eventloop_tick(timer_tick)
  end

  def get_eventloop_tick()
    TclTkLib.get_eventloop_tick
  end

  def set_no_event_wait(wait)
    TclTkLib.set_no_even_wait(wait)
  end

  def get_no_event_wait()
    TclTkLib.get_no_eventloop_wait
  end

  def set_eventloop_weight(loop_max, no_event_tick)
    TclTkLib.set_eventloop_weight(loop_max, no_event_tick)
  end

  def get_eventloop_weight()
    TclTkLib.get_eventloop_weight
  end

  def restart(app_name = nil, keys = {})
    TkCore::INTERP.init_ip_internal

    tk_call('set', 'argv0', app_name) if app_name
    if keys.kind_of?(Hash)
      # tk_call('set', 'argc', keys.size * 2)
      tk_call('set', 'argv', hash_kv(keys).join(' '))
    end

    INTERP.restart
    nil
  end

  def event_generate(win, context, keys=nil)
    #win = win.path if win.kind_of?(TkObject)
    if context.kind_of?(TkEvent::Event)
      context.generate(win, ((keys)? keys: {}))
    elsif keys
      tk_call_without_enc('event', 'generate', win,
                          "<#{tk_event_sequence(context)}>",
                          *hash_kv(keys, true))
    else
      tk_call_without_enc('event', 'generate', win,
                          "<#{tk_event_sequence(context)}>")
    end
    nil
  end

  def messageBox(keys)
    tk_call('tk_messageBox', *hash_kv(keys))
  end

  def getOpenFile(keys = nil)
    tk_call('tk_getOpenFile', *hash_kv(keys))
  end
  def getMultipleOpenFile(keys = nil)
    simplelist(tk_call('tk_getOpenFile', '-multiple', '1', *hash_kv(keys)))
  end

  def getSaveFile(keys = nil)
    tk_call('tk_getSaveFile', *hash_kv(keys))
  end

  def chooseColor(keys = nil)
    tk_call('tk_chooseColor', *hash_kv(keys))
  end

  def chooseDirectory(keys = nil)
    tk_call('tk_chooseDirectory', *hash_kv(keys))
  end

  def _ip_eval_core(enc_mode, cmd_string)
    case enc_mode
    when nil
      res = INTERP._eval(cmd_string)
    when false
      res = INTERP._eval_without_enc(cmd_string)
    when true
      res = INTERP._eval_with_enc(cmd_string)
    end
    if  INTERP._return_value() != 0
      fail RuntimeError, res, error_at
    end
    return res
  end
  private :_ip_eval_core

  def ip_eval(cmd_string)
    _ip_eval_core(nil, cmd_string)
  end

  def ip_eval_without_enc(cmd_string)
    _ip_eval_core(false, cmd_string)
  end

  def ip_eval_with_enc(cmd_string)
    _ip_eval_core(true, cmd_string)
  end

  def _ip_invoke_core(enc_mode, *args)
    case enc_mode
    when false
      res = INTERP._invoke_without_enc(*args)
    when nil
      res = INTERP._invoke(*args)
    when true
      res = INTERP._invoke_with_enc(*args)
    end
    if  INTERP._return_value() != 0
      fail RuntimeError, res, error_at
    end
    return res
  end
  private :_ip_invoke_core

  def ip_invoke(*args)
    _ip_invoke_core(nil, *args)
  end

  def ip_invoke_without_enc(*args)
    _ip_invoke_core(false, *args)
  end

  def ip_invoke_with_enc(*args)
    _ip_invoke_core(true, *args)
  end

  def _tk_call_core(enc_mode, *args)
    ### puts args.inspect if $DEBUG
    #args.collect! {|x|ruby2tcl(x, enc_mode)}
    #args.compact!
    #args.flatten!
    args = _conv_args([], enc_mode, *args)
    puts 'invoke args => ' + args.inspect if $DEBUG
    ### print "=> ", args.join(" ").inspect, "\n" if $DEBUG
    begin
      # res = INTERP._invoke(enc_mode, *args)
      res = _ip_invoke_core(enc_mode, *args)
      # >>>>>  _invoke returns a TAINTED string  <<<<<
    rescue NameError => err
      # err = $!
      begin
        args.unshift "unknown"
        #res = INTERP._invoke(enc_mode, *args)
        res = _ip_invoke_core(enc_mode, *args)
        # >>>>>  _invoke returns a TAINTED string  <<<<<
      rescue StandardError => err2
        fail err2 unless /^invalid command/ =~ err2.message
        fail err
      end
    end
    if  INTERP._return_value() != 0
      fail RuntimeError, res, error_at
    end
    ### print "==> ", res.inspect, "\n" if $DEBUG
    return res
  end
  private :_tk_call_core

  def tk_call(*args)
    _tk_call_core(nil, *args)
  end

  def tk_call_without_enc(*args)
    _tk_call_core(false, *args)
  end

  def tk_call_with_enc(*args)
    _tk_call_core(true, *args)
  end

  def _tk_call_to_list_core(depth, arg_enc, val_enc, *args)
    args = _conv_args([], arg_enc, *args)
    val = _tk_call_core(false, *args)
    if !depth.kind_of?(Integer) || depth == 0
      tk_split_simplelist(val, false, val_enc)
    else
      tk_split_list(val, depth, false, val_enc)
    end
  end
  #private :_tk_call_to_list_core

  def tk_call_to_list(*args)
    _tk_call_to_list_core(-1, nil, true, *args)
  end

  def tk_call_to_list_without_enc(*args)
    _tk_call_to_list_core(-1, false, false, *args)
  end

  def tk_call_to_list_with_enc(*args)
    _tk_call_to_list_core(-1, true, true, *args)
  end

  def tk_call_to_simplelist(*args)
    _tk_call_to_list_core(0, nil, true, *args)
  end

  def tk_call_to_simplelist_without_enc(*args)
    _tk_call_to_list_core(0, false, false, *args)
  end

  def tk_call_to_simplelist_with_enc(*args)
    _tk_call_to_list_core(0, true, true, *args)
  end
end


