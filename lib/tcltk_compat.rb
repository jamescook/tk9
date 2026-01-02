# frozen_string_literal: true
#
# Legacy compatibility wrappers for TclTkLib
#
# The old tcltklib.c defined constants under nested modules (EventFlag, etc).
# Our new bridge defines them at the TclTkLib top level. These wrappers
# provide backwards compatibility for code expecting the old structure.

# ---------------------------------------------------------
# Safe signal handling for SIGTERM/SIGINT
#
# Tcl/Tk's macOS signal handler (TkMacOSXSignalHandler) calls Tcl_Exit
# directly from the signal context, which can cause recursive lock crashes
# when signals arrive during event processing.
#
# We install our own handlers that defer cleanup to Tk's event loop,
# ensuring safe shutdown.
# ---------------------------------------------------------
%w[TERM INT].each do |sig|
  Signal.trap(sig) do
    if TclTkIp.instance_count > 0
      begin
        # Defer to Tk's event loop for safe cleanup
        TkCore.interp.after_idle { Tk.root.destroy }
      rescue RuntimeError, TclTkLib::TclError
        # Interp deleted, multiple interps, or Tk already torn down - just exit
        exit
      end
    else
      exit
    end
  end
end

class TclTkIp
  # ---------------------------------------------------------
  # Modern API (defined in tcltkbridge.c):
  #
  #   tcl_eval(script)           - Evaluate Tcl script
  #   tcl_invoke(*args)          - Call Tcl command with args (no substitution)
  #   tcl_get_var(name)          - Get variable value
  #   tcl_set_var(name, value)   - Set variable value
  #   tcl_split_list(str)        - Parse Tcl list into Ruby array
  #
  # The underscore-prefixed methods below are LEGACY compatibility
  # for tk.rb internals. New code should use the methods above.
  # ---------------------------------------------------------

  # Unset variable (tolerant - no error if doesn't exist)
  # Uses tcl_eval because Tcl_UnsetVar doesn't have a "nocomplain" mode
  def tcl_unset_var(varname)
    tcl_eval("unset -nocomplain -- #{varname}")
  end

  # Array element access - Tcl arrays use varname(index) syntax
  def tcl_get_var2(varname, index)
    tcl_get_var("#{varname}(#{index})")
  end

  def tcl_set_var2(varname, index, value)
    tcl_set_var("#{varname}(#{index})", value)
  end

  def tcl_unset_var2(varname, index)
    tcl_eval("unset -nocomplain -- #{varname}(#{index})")
  end

  # ---------------------------------------------------------
  # Legacy compatibility aliases (DEPRECATED - use tcl_* methods)
  # These exist only because tk.rb uses them internally.
  # ---------------------------------------------------------
  alias _invoke_without_enc tcl_invoke
  alias _invoke tcl_invoke
  alias _get_global_var tcl_get_var
  alias _set_global_var tcl_set_var
  alias _unset_global_var tcl_unset_var
  alias _get_global_var2 tcl_get_var2
  alias _set_global_var2 tcl_set_var2
  alias _unset_global_var2 tcl_unset_var2
  alias _split_tklist tcl_split_list

  # Legacy return value check. Old bridge stored error code separately;
  # our bridge raises immediately on error. So if this is called, it means
  # the previous command succeeded (0 = TCL_OK).
  def _return_value = 0

  # Legacy encoding methods - no-ops since modern Tcl/Ruby use UTF-8 natively
  # TODO: Remove these and fix 150+ callsites in tk.rb
  def _toUTF8(str, enc = nil) = str.to_s
  def _fromUTF8(str, enc = nil) = str.to_s

  # Legacy encoding table method - removed in new bridge.
  def encoding_table
    raise NotImplementedError,
      "encoding_table removed: modern Tcl/Ruby use UTF-8 natively. " \
      "See ext/tk/extconf.rb for details."
  end

  # Thread-aware vwait/tkwait - in our simplified bridge, just use regular versions
  def _thread_vwait(var)
    tcl_eval("vwait #{var}")
  end

  def _thread_tkwait(mode, target)
    tcl_eval("tkwait #{mode} #{target}")
  end

  # Merge strings into a Tcl list with proper quoting
  def _merge_tklist(*args)
    TclTkLib._merge_tklist(*args)
  end

  # Create a Tcl proc. Used by tk.rb to set up callback infrastructure.
  def add_tk_procs(name, args, body)
    tcl_eval("proc #{name} {#{args}} {#{body}}")
  end

  # ---------------------------------------------------------
  # Instance methods for after/after_idle/after_cancel
  # These are the preferred API - they're explicit about which
  # interpreter is being used.
  # ---------------------------------------------------------

  def after(ms, cmd = nil, &block)
    cmd ||= block
    raise ArgumentError, "no callback given" unless cmd

    cb_id = nil
    cb_id = register_callback(proc {
      unregister_callback(cb_id)
      cmd.call
    })
    tcl_eval("after #{ms} {ruby_callback #{cb_id}}")
    cb_id
  end

  def after_idle(cmd = nil, &block)
    cmd ||= block
    raise ArgumentError, "no callback given" unless cmd

    cb_id = nil
    cb_id = register_callback(proc {
      unregister_callback(cb_id)
      cmd.call
    })
    tcl_eval("after idle {ruby_callback #{cb_id}}")
    cb_id
  end

  def after_cancel(cb_id)
    tcl_eval("after cancel {ruby_callback #{cb_id}}")
    unregister_callback(cb_id)
  end
end

module TkCore
  # ---------------------------------------------------------
  # TkCore.on_main_thread { block } - Execute block on main Tcl thread
  #
  # If called from main thread: executes immediately
  # If called from background thread: queues and waits for completion
  #
  # This is essential for thread-safe Tk access. Background threads
  # cannot call Tcl/Tk directly - they must use this wrapper.
  #
  # Example:
  #   Thread.new do
  #     TkCore.on_main_thread { label.text = "Updated from thread" }
  #   end
  # ---------------------------------------------------------
  def self.on_main_thread(&block)
    ip = interp
    if ip.on_main_thread?
      yield
    else
      # Queue to main thread and wait for completion
      result = nil
      error = nil
      done = Queue.new

      ip.queue_for_main(proc {
        begin
          result = yield
        rescue => e
          error = e
        ensure
          done << true
        end
      })

      done.pop  # Wait for completion
      raise error if error
      result
    end
  end

  # ---------------------------------------------------------
  # TkCore.interp - Get the interpreter with runtime safety checks
  #
  # - Lazily creates an interpreter if none exists
  # - Raises if multiple interpreters exist (ambiguous)
  # - Preferred over the deprecated INTERP constant
  # ---------------------------------------------------------
  def self.interp
    count = TclTkIp.instance_count

    if count == 0
      # Lazy creation - create the default interpreter
      @default_interp = TclTkIp.new
    elsif count == 1
      @default_interp ||= TclTkIp.instances.first
    else
      raise RuntimeError,
        "Multiple Tcl interpreters exist (#{count}). " \
        "Use interp.after(...) on a specific interpreter instance " \
        "instead of Tk.after(...)"
    end

    @default_interp
  end

  # ---------------------------------------------------------
  # Intercept access to INTERP constant for deprecation warning
  # ---------------------------------------------------------
  def self.const_missing(name)
    if name == :INTERP
      warn "TkCore::INTERP is deprecated. Use TkCore.interp or call methods " \
           "directly on a TclTkIp instance.", uplevel: 1
      interp
    else
      super
    end
  end

  # ---------------------------------------------------------
  # Module methods that delegate to the (single) interpreter
  # These use TkCore.interp which enforces single-interp or errors
  # ---------------------------------------------------------
  def after(ms, cmd = nil, &block)
    TkCore.interp.after(ms, cmd, &block)
  end

  def after_idle(cmd = nil, &block)
    TkCore.interp.after_idle(cmd, &block)
  end

  def after_cancel(cb_id)
    TkCore.interp.after_cancel(cb_id)
  end
end

module TclTkLib
  # Warn if called from inside a Tk callback (unsafe for exit/destroy)
  def self.warn_if_in_callback(operation)
    if in_callback?
      warn "WARNING: #{operation} called from inside a Tk callback. " \
           "This can cause crashes or undefined behavior. " \
           "Use Tk.after(0) { #{operation} } to defer the operation.", uplevel: 2
    end
  end

  # Event flags for do_one_event.
  # Values come from Tcl's tcl.h (TCL_WINDOW_EVENTS, etc).
  # Our C bridge exposes these as TclTkLib::WINDOW_EVENTS etc.
  # Legacy code expects TclTkLib::EventFlag::WINDOW etc.
  module EventFlag
    NONE      = 0
    WINDOW    = TclTkLib::WINDOW_EVENTS
    FILE      = TclTkLib::FILE_EVENTS
    TIMER     = TclTkLib::TIMER_EVENTS
    IDLE      = TclTkLib::IDLE_EVENTS
    ALL       = TclTkLib::ALL_EVENTS
    DONT_WAIT = TclTkLib::DONT_WAIT
  end

  class << self
    # Delegate to C Tk_MainLoop - see tcltkbridge.c for docs
    def mainloop(check_root = true)
      TkCore.interp.mainloop
    end

    # Stubs for legacy thread/event loop methods
    def mainloop_abort_on_exception; @abort_on_exception; end
    def mainloop_abort_on_exception=(val); @abort_on_exception = val; end
    def set_eventloop_window_mode(mode); end
    def get_eventloop_window_mode; true; end
    def set_eventloop_tick(tick); end
    def get_eventloop_tick; 0; end
    def set_no_event_wait(tick); end
    def get_no_event_wait; 0; end
    def set_eventloop_weight(loop_max, no_event_tick); end
    def get_eventloop_weight; [800, 10]; end
    def mainloop_watchdog(check_root = true); mainloop(check_root); end
    def mainloop_thread?; nil; end

    def do_one_event(flags = ALL_EVENTS)
      TkCore.interp.do_one_event(flags)
    end

    # Legacy encoding methods - no-ops since modern Tcl/Ruby use UTF-8 natively
    def _toUTF8(str, enc = nil)
      str.to_s
    end

    def _fromUTF8(str, enc = nil)
      str.to_s
    end

    def encoding_system
      'utf-8'
    end

    def encoding_system=(enc)
      # No-op - modern Tcl/Ruby use UTF-8 natively
    end

    # Split a Tcl list string into a Ruby array - used by tkutil.c
    def _split_tklist(str)
      TkCore.interp.tcl_split_list(str)
    end

    # _merge_tklist is now defined in C (tcltkbridge.c) for performance
  end
end
