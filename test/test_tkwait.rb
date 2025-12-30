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

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require_relative 'tk_test_helper'

class TestTkWait < Minitest::Test
  include TkTestHelper

  # Test tkwait variable - wait for a TkVariable to change
  # Exercises ip_rbTkWaitObjCmd with "variable" option
  def test_tkwait_variable
    assert_tk_test("TkVariable#wait should unblock when variable changes") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        var = TkVariable.new("initial")
        TkTimer.new(100, 1) { var.value = "changed" }.start
        var.wait
        raise "variable value not changed" unless var.value == "changed"
        root.destroy
      RUBY
    end
  end

  # Test tkwait visibility - wait for a window to become visible
  # Exercises ip_rbTkWaitObjCmd with "visibility" option
  def test_tkwait_visibility
    assert_tk_test("wait_visibility should return when window becomes visible") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        toplevel = TkToplevel.new(root)  # don't withdraw - let it become visible

        visibility_received = false
        toplevel.bind('Visibility') { visibility_received = true }

        # Safety net in case visibility never fires
        TkTimer.new(500, 1) { toplevel.destroy rescue nil }.start
        toplevel.wait_visibility

        raise "visibility event never fired" unless visibility_received
        root.destroy
      RUBY
    end
  end

  # Test tkwait window - wait for a window to be destroyed
  # Exercises ip_rbTkWaitObjCmd with "window" option
  def test_tkwait_window_destroy
    assert_tk_test("wait_destroy should return after window is destroyed") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        toplevel = TkToplevel.new(root) { withdraw }
        TkTimer.new(100, 1) { toplevel.destroy }.start
        toplevel.wait_destroy
        root.destroy
      RUBY
    end
  end

  # Test tkwait variable from non-eventloop thread
  # Exercises ip_rb_threadVwaitObjCmd (threaded version of vwait)
  def test_tkwait_variable_from_thread
    assert_tk_test("vwait from non-eventloop thread should work") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        var = TkVariable.new("initial")
        $done = false

        # Run event loop in separate thread
        eventloop_thread = Thread.new do
          loop do
            Tk.update
            sleep 0.01
            break if $done
          end
        end

        sleep 0.05  # let eventloop thread start

        # Timer will fire in eventloop thread and change variable
        TkTimer.new(100, 1) { var.value = "changed" }.start

        # This call happens from MAIN thread (not eventloop thread)
        # so it should go through ip_rb_threadVwaitObjCmd
        var.wait

        raise "variable not changed" unless var.value == "changed"

        $done = true
        eventloop_thread.join(1)
        root.destroy
      RUBY
    end
  end

  # Test tkwait with wrong arguments raises an error
  # Exercises the error handling path in ip_rbTkWaitObjCmd
  def test_tkwait_wrong_args
    assert_tk_test("tkwait with no arguments should raise an error") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        begin
          Tk.ip_eval("tkwait")
          raise "expected error was not raised"
        rescue => e
          unless e.message.include?("wrong") || e.message.include?("argument")
            raise "unexpected error: \#{e.message}"
          end
        end
        root.destroy
      RUBY
    end
  end

  # Test tkwait with invalid option
  # Exercises the option parsing path in ip_rbTkWaitObjCmd
  def test_tkwait_invalid_option
    assert_tk_test("tkwait with invalid option should raise an error") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        begin
          Tk.ip_eval("tkwait badoption foo")
          raise "expected error was not raised"
        rescue => e
          unless e.message.include?("bad option") || e.message.include?("must be")
            raise "unexpected error: \#{e.message}"
          end
        end
        root.destroy
      RUBY
    end
  end
end
