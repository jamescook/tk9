# frozen_string_literal: true

#
# TclTkBridge Ruby wrapper
#
# Provides callback dispatch without rb_funcall from C.
# Callbacks are queued in a Tcl variable and dispatched by Ruby's event loop.
#
# Instance-based design supports multiple interpreters.
#

require 'tcltkbridge'
require_relative 'tcl_list_parser'

module Tk
  class Bridge
    # Tcl variable used as callback queue.
    # Same name is fine across interpreters - each Tcl interp has isolated
    # variable namespace, so ::_ruby_callback_queue in interp1 is completely
    # separate from ::_ruby_callback_queue in interp2.
    CALLBACK_QUEUE_VAR = "::_ruby_callback_queue"

    # Default instance for simple single-interpreter usage
    @default = nil

    class << self
      # Get or create the default bridge instance
      def default
        @default ||= new
      end

      # Reset default instance (mainly for testing)
      def reset_default!
        @default = nil
      end
    end

    attr_reader :interp

    def initialize
      @interp = TclTkBridge::Interp.new
      @callbacks = {}
      @next_callback_id = 0
      @running = false

      # Initialize the callback queue as empty list
      @interp.tcl_eval("set #{CALLBACK_QUEUE_VAR} {}")
    end

    # Register a Ruby proc/block to be callable from Tcl
    # Returns the callback ID
    def register_callback(proc = nil, &block)
      callback = proc || block
      raise ArgumentError, "No callback provided" unless callback

      id = "cb_#{@next_callback_id += 1}"
      @callbacks[id] = callback
      id
    end

    # Generate Tcl command string for a callback
    # Usage: tcl_callback_command(id, "%W", "%x", "%y")
    def tcl_callback_command(id, *substitutions)
      if substitutions.empty?
        "lappend #{CALLBACK_QUEUE_VAR} [list #{id}]"
      else
        "lappend #{CALLBACK_QUEUE_VAR} [list #{id} #{substitutions.join(' ')}]"
      end
    end

    # Unregister a callback
    def unregister_callback(id)
      @callbacks.delete(id)
    end

    # Process pending callbacks from the Tcl queue
    def dispatch_pending_callbacks
      queue_content = @interp.tcl_get_var(CALLBACK_QUEUE_VAR)
      return if queue_content.nil? || queue_content.empty?

      # Clear the queue immediately
      @interp.tcl_set_var(CALLBACK_QUEUE_VAR, "")

      # Parse the Tcl list and dispatch each callback
      parse_tcl_list(queue_content).each do |entry|
        dispatch_single_callback(entry)
      end
    end

    # Main event loop
    def mainloop
      @running = true
      while @running
        # Block until Tcl/Tk event arrives (no polling, no sleep)
        @interp.do_one_event(TclTkBridge::ALL_EVENTS)

        # Dispatch any queued Ruby callbacks
        dispatch_pending_callbacks

        # Check if main window still exists
        break unless window_exists?(".")
      end
    end

    # Stop the event loop
    def stop
      @running = false
    end

    # Check if a window exists
    def window_exists?(path)
      result = @interp.tcl_eval("winfo exists #{path}")
      result == "1"
    rescue TclTkBridge::TclError
      false  # Interpreter deleted or app destroyed
    end

    # Convenience: eval Tcl script
    def eval(script)
      @interp.tcl_eval(script)
    end

    # Convenience: invoke Tcl command
    def invoke(*args)
      @interp.tcl_invoke(*args)
    end

    # Tcl/Tk version info
    def tcl_version
      @interp.tcl_version
    end

    def tk_version
      @interp.tk_version
    end

    # Wait for a Tcl variable to change.
    # Unlike Tcl's native vwait, this keeps Ruby callbacks firing.
    #
    # @param varname [String] Name of Tcl variable to watch
    def vwait(varname)
      flag_var = "::_ruby_vwait_flag_#{varname.gsub(/[^a-zA-Z0-9]/, '_')}"
      @interp.tcl_set_var(flag_var, "0")

      # Set up trace - when variable is written, set our flag
      trace_script = "set #{flag_var} 1"
      @interp.tcl_eval("trace add variable #{varname} write {apply {{args} {#{trace_script}}}}")

      # Event loop until flag is set
      wait_loop { @interp.tcl_get_var(flag_var) == "1" }

      # Clean up
      @interp.tcl_eval("trace remove variable #{varname} write {apply {{args} {#{trace_script}}}}")
    end

    # Wait for a window to be destroyed.
    # Unlike Tcl's native tkwait, this keeps Ruby callbacks firing.
    #
    # @param path [String] Window path (e.g., ".dialog")
    def tkwait_window(path)
      wait_loop { !window_exists?(path) }
    end

    # Wait for a window to become visible.
    # Unlike Tcl's native tkwait, this keeps Ruby callbacks firing.
    #
    # @param path [String] Window path (e.g., ".dialog")
    def tkwait_visibility(path)
      flag_var = "::_ruby_visibility_flag"
      @interp.tcl_set_var(flag_var, "0")

      # Bind to Visibility event
      @interp.tcl_eval("bind #{path} <Visibility> {set #{flag_var} 1}")

      wait_loop do
        @interp.tcl_get_var(flag_var) == "1" || !window_exists?(path)
      end

      # Clean up
      @interp.tcl_eval("bind #{path} <Visibility> {}") if window_exists?(path)
    end

    private

    # Shared wait loop - processes events and callbacks until condition is met
    def wait_loop
      loop do
        # Block until event arrives (no polling)
        @interp.do_one_event(TclTkBridge::ALL_EVENTS)
        dispatch_pending_callbacks
        break if yield
      end
    end

    # Parse a Tcl list string into Ruby array of arrays
    # Uses pure Ruby parser (faster than Tcl eval with YJIT)
    def parse_tcl_list(tcl_list)
      return [] if tcl_list.nil? || tcl_list.empty?

      # Parse outer list, then parse each inner element
      TclListParser.parse(tcl_list).map do |element|
        TclListParser.parse(element)
      end
    end

    def dispatch_single_callback(entry)
      return if entry.empty?

      id = entry[0]
      args = entry[1..]

      callback = @callbacks[id]
      if callback
        begin
          callback.call(*args)
        rescue => e
          warn "Callback #{id} raised: #{e.message}"
          warn e.backtrace.first(5).join("\n")
        end
      else
        warn "Unknown callback ID: #{id}"
      end
    end
  end
end
