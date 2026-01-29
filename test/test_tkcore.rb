# frozen_string_literal: true

# Tests for TkCore module - interpreter, callbacks, timing, and inter-app communication
#
# See: lib/tkcore.rb

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkCore < Minitest::Test
  include TkTestHelper

  # --- after_idle (L287-293) ---

  def test_after_idle
    assert_tk_app("after_idle schedules callback for idle time", method(:app_after_idle))
  end

  def app_after_idle
    require 'tk'

    errors = []
    called = false

    after_id = Tk.after_idle { called = true }

    errors << "after_idle should return an after ID string" unless after_id.is_a?(String)
    errors << "after_idle should store cmdid" unless after_id.instance_variable_get('@cmdid')

    # Process events to trigger idle callback
    Tk.update
    errors << "idle callback should have been called" unless called

    raise errors.join("\n") unless errors.empty?
  end

  # --- after_cancel (L295-302) ---

  def test_after_cancel
    assert_tk_app("after_cancel cancels scheduled callback", method(:app_after_cancel))
  end

  def app_after_cancel
    require 'tk'

    errors = []
    called = false

    # Schedule something far in the future
    after_id = Tk.after(10000) { called = true }
    cmdid = after_id.instance_variable_get('@cmdid')
    errors << "after should store cmdid" unless cmdid

    # Cancel it
    result = Tk.after_cancel(after_id)
    errors << "after_cancel should return the after_id" unless result == after_id
    errors << "after_cancel should clear cmdid" if after_id.instance_variable_get('@cmdid')

    # Callback should not be called
    Tk.update
    errors << "cancelled callback should not be called" if called

    raise errors.join("\n") unless errors.empty?
  end

  # --- scaling (L308-314) ---

  def test_scaling_get
    assert_tk_app("scaling returns current scale factor", method(:app_scaling_get))
  end

  def app_scaling_get
    require 'tk'

    errors = []

    scale = Tk.scaling
    errors << "scaling should return a Float, got #{scale.class}" unless scale.is_a?(Float)
    errors << "scaling should be positive, got #{scale}" unless scale > 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_scaling_set
    assert_tk_app("scaling can set scale factor", method(:app_scaling_set))
  end

  def app_scaling_set
    require 'tk'

    errors = []

    original = Tk.scaling

    # Set a new scaling factor
    Tk.scaling(1.5)
    new_scale = Tk.scaling
    errors << "scaling should be 1.5 after setting, got #{new_scale}" unless (new_scale - 1.5).abs < 0.01

    # Restore original
    Tk.scaling(original)

    raise errors.join("\n") unless errors.empty?
  end

  # --- inactive (L323-334) ---

  def test_inactive
    assert_tk_app("inactive returns milliseconds since last user activity", method(:app_inactive))
  end

  def app_inactive
    require 'tk'

    errors = []

    inactive_ms = Tk.inactive
    errors << "inactive should return an Integer, got #{inactive_ms.class}" unless inactive_ms.is_a?(Integer)
    errors << "inactive should be non-negative, got #{inactive_ms}" unless inactive_ms >= 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_reset_inactive
    assert_tk_app("reset_inactive resets the inactivity timer", method(:app_reset_inactive))
  end

  def app_reset_inactive
    require 'tk'

    errors = []

    # Reset inactivity timer
    Tk.reset_inactive

    # Get time after reset - should be very small
    after_reset = Tk.inactive
    errors << "inactive after reset should be small, got #{after_reset}" unless after_reset < 1000

    raise errors.join("\n") unless errors.empty?
  end

  # --- callback_break/continue/return (L220-230) ---

  def test_callback_continue
    assert_tk_app("callback_continue raises TkCallbackContinue", method(:app_callback_continue))
  end

  def app_callback_continue
    require 'tk'

    errors = []

    begin
      Tk.callback_continue
      errors << "callback_continue should raise TkCallbackContinue"
    rescue TkCallbackContinue => e
      errors << "message should mention 'continue'" unless e.message.include?('continue')
    rescue => e
      errors << "should raise TkCallbackContinue, got #{e.class}"
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_callback_return
    assert_tk_app("callback_return raises TkCallbackReturn", method(:app_callback_return))
  end

  def app_callback_return
    require 'tk'

    errors = []

    begin
      Tk.callback_return
      errors << "callback_return should raise TkCallbackReturn"
    rescue TkCallbackReturn => e
      errors << "message should mention 'return'" unless e.message.include?('return')
    rescue => e
      errors << "should raise TkCallbackReturn, got #{e.class}"
    end

    raise errors.join("\n") unless errors.empty?
  end

  # --- appname (L336-338) ---

  def test_appname_get
    assert_tk_app("appname returns application name", method(:app_appname_get))
  end

  def app_appname_get
    require 'tk'

    errors = []

    name = Tk.appname
    errors << "appname should return a String, got #{name.class}" unless name.is_a?(String)
    errors << "appname should not be empty" if name.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_appname_set
    assert_tk_app("appname can set application name", method(:app_appname_set))
  end

  def app_appname_set
    require 'tk'

    errors = []

    # Set a new name (Tk may append a number if name conflicts)
    Tk.appname('TestApp')
    new_name = Tk.appname
    errors << "appname should contain 'TestApp', got '#{new_name}'" unless new_name.include?('TestApp')

    raise errors.join("\n") unless errors.empty?
  end

  # --- windowingsystem (L304-306) ---

  def test_windowingsystem
    assert_tk_app("windowingsystem returns platform windowing system", method(:app_windowingsystem))
  end

  def app_windowingsystem
    require 'tk'

    errors = []

    ws = Tk.windowingsystem
    errors << "windowingsystem should return a String, got #{ws.class}" unless ws.is_a?(String)
    # Should be one of: x11, win32, aqua
    valid = %w[x11 win32 aqua]
    errors << "windowingsystem should be one of #{valid}, got '#{ws}'" unless valid.include?(ws)

    raise errors.join("\n") unless errors.empty?
  end

  # --- mainloop_thread? (L407-412) ---

  def test_mainloop_thread
    assert_tk_app("mainloop_thread? returns thread status", method(:app_mainloop_thread))
  end

  def app_mainloop_thread
    require 'tk'

    errors = []

    # Before mainloop, should be nil (no mainloop running)
    # During our test, we're in a pseudo-mainloop via update
    result = Tk.mainloop_thread?
    # Result can be true, false, or nil
    errors << "mainloop_thread? should return true, false, or nil" unless [true, false, nil].include?(result)

    raise errors.join("\n") unless errors.empty?
  end

  # --- load_cmd_on_ip (L275-277) ---

  def test_load_cmd_on_ip
    assert_tk_app("load_cmd_on_ip loads Tcl command", method(:app_load_cmd_on_ip))
  end

  def app_load_cmd_on_ip
    require 'tk'

    errors = []

    # Try to load a standard Tk command
    # Returns true if loaded, false if already loaded or not found
    result = Tk.load_cmd_on_ip('button')
    errors << "load_cmd_on_ip should return boolean, got #{result.class}" unless [true, false].include?(result)

    raise errors.join("\n") unless errors.empty?
  end

  # --- info (L396-398) ---

  def test_info_commands
    assert_tk_app("info returns Tcl interpreter info", method(:app_info_commands))
  end

  def app_info_commands
    require 'tk'

    errors = []

    # Get list of commands
    result = Tk.info('commands', 'button')
    errors << "info commands should return String, got #{result.class}" unless result.is_a?(String)
    errors << "info commands 'button' should find button command" unless result.include?('button')

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.after basic (L509-515) ---

  def test_after_basic
    assert_tk_app("Tk.after schedules callback", method(:app_after_basic))
  end

  def app_after_basic
    require 'tk'

    errors = []
    called = false

    after_id = Tk.after(10) { called = true }
    errors << "after should return an ID string" unless after_id.is_a?(String)

    # Process events until callback fires
    start = Time.now
    while !called && (Time.now - start) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "callback should have been called" unless called

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.after on deleted interpreter ---

  def test_after_on_deleted_interp
    assert_tk_app("Tk.after fails gracefully on deleted interp", method(:app_after_deleted_interp))
  end

  def app_after_deleted_interp
    require 'tk'

    errors = []

    # Create a second interpreter
    interp2 = TclTkIp.new

    # Delete it
    interp2.delete

    # Try to call after on the deleted interpreter
    begin
      interp2.after(10) { }
      errors << "after on deleted interp should raise"
    rescue => e
      # Expected - should raise some kind of error
      errors << "error should mention deleted, got: #{e.message}" unless e.message.include?('deleted')
    end

    raise errors.join("\n") unless errors.empty?
  end
end
