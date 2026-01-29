# frozen_string_literal: true

# Tests for tkwait functionality (blocking waits on Tk events)
#
# Key C function exercised:
#   - ip_rbTkWaitObjCmd (handles tkwait variable/visibility/window)
#
# tkwait blocks the caller until a condition is met:
#   - variable: waits until a Tcl variable changes
#   - visibility: waits until a window becomes visible
#   - window: waits until a window is destroyed

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkWait < Minitest::Test
  include TkTestHelper

  # Test tkwait variable - wait for a TkVariable to change
  # Exercises ip_rbTkWaitObjCmd with "variable" option
  def test_tkwait_variable
    assert_tk_app("TkVariable#wait should unblock when variable changes", method(:app_tkwait_variable))
  end

  def app_tkwait_variable
    require 'tk'
    var = TkVariable.new("initial")
    TkTimer.new(100, 1) { var.value = "changed" }.start
    var.wait
    raise "variable value not changed" unless var.value == "changed"
  end

  # Test tkwait visibility - wait for a window to become visible
  # Exercises ip_rbTkWaitObjCmd with "visibility" option
  def test_tkwait_visibility
    assert_tk_app("wait_visibility should return when window becomes visible", method(:app_tkwait_visibility))
  end

  def app_tkwait_visibility
    require 'tk'
    toplevel = TkToplevel.new(root)  # don't withdraw - let it become visible

    visibility_received = false
    toplevel.bind('Visibility') { visibility_received = true }

    # Safety net in case visibility never fires
    TkTimer.new(500, 1) { toplevel.destroy rescue nil }.start
    toplevel.wait_visibility

    raise "visibility event never fired" unless visibility_received
  end

  # Test tkwait window - wait for a window to be destroyed
  # Exercises ip_rbTkWaitObjCmd with "window" option
  def test_tkwait_window_destroy
    assert_tk_app("wait_destroy should return after window is destroyed", method(:app_tkwait_window_destroy))
  end

  def app_tkwait_window_destroy
    require 'tk'
    toplevel = TkToplevel.new(root) { withdraw }
    TkTimer.new(100, 1) { toplevel.destroy }.start
    toplevel.wait_destroy
  end

  # Test tkwait variable from non-eventloop thread
  # Exercises ip_rb_threadVwaitObjCmd (threaded version of vwait)
  # SKIP: Requires thread-aware event loop machinery (removed in simplified bridge)
  def test_tkwait_variable_from_thread
    skip "vwait from non-main thread not supported (Tcl notifier requires main thread)"
  end

  # Test tkwait with wrong arguments raises an error
  # Exercises the error handling path in ip_rbTkWaitObjCmd
  def test_tkwait_wrong_args
    assert_tk_app("tkwait with no arguments should raise an error", method(:app_tkwait_wrong_args))
  end

  def app_tkwait_wrong_args
    require 'tk'
    begin
      Tk.ip_eval("tkwait")
      raise "expected error was not raised"
    rescue => e
      unless e.message.include?("wrong") || e.message.include?("argument")
        raise "unexpected error: #{e.message}"
      end
    end
  end

  # Test tkwait with invalid option
  # Exercises the option parsing path in ip_rbTkWaitObjCmd
  def test_tkwait_invalid_option
    assert_tk_app("tkwait with invalid option should raise an error", method(:app_tkwait_invalid_option))
  end

  def app_tkwait_invalid_option
    require 'tk'
    begin
      Tk.ip_eval("tkwait badoption foo")
      raise "expected error was not raised"
    rescue => e
      unless e.message.include?("bad option") || e.message.include?("must be")
        raise "unexpected error: #{e.message}"
      end
    end
  end
end
