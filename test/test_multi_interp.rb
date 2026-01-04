# frozen_string_literal: true

# Tests for multiple Tcl interpreter support (slave interpreters)
#
# Key C functions exercised:
#   - ip_create_slave (creates a child interpreter)
#   - delete_slaves (cleans up child interpreters on parent destruction)
#   - ip_finalize (interpreter cleanup)
#
# Slave interpreters are a Tcl feature for creating sandboxed child
# interpreters within a parent interpreter.

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestMultiInterp < Minitest::Test
  include TkTestHelper

  # Test creating and destroying a slave interpreter
  # Exercises ip_create_slave and delete_slaves
  def test_create_and_destroy_slave
    assert_tk_test("should create and destroy slave interpreter") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        # Get the underlying TclTkIp object
        interp = TkCore::INTERP

        # Create a slave interpreter
        slave = interp.create_slave("test_slave", true)  # true = safe slave
        raise "slave should not be nil" if slave.nil?

        # Verify the slave exists by listing slaves
        slaves_list = interp._eval("interp slaves")
        raise "test_slave not in slaves list" unless slaves_list.include?("test_slave")

        # Destroy the parent - this should trigger delete_slaves
        root.destroy
      RUBY
    end
  end

  # Test that slave is cleaned up when parent is destroyed
  # Exercises delete_slaves code path
  def test_slave_cleanup_on_parent_destroy
    assert_tk_test("slave should be deleted when parent is destroyed") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        interp = TkCore::INTERP

        # Create multiple slaves
        slave1 = interp.create_slave("slave1", true)
        slave2 = interp.create_slave("slave2", false)  # unsafe slave

        # Verify both exist
        slaves_list = interp._eval("interp slaves")
        raise "slave1 missing" unless slaves_list.include?("slave1")
        raise "slave2 missing" unless slaves_list.include?("slave2")

        # Destroying root should clean up all slaves via delete_slaves()
        root.destroy
      RUBY
    end
  end

  # Test basic slave interpreter operations
  def test_slave_eval
    assert_tk_test("should be able to eval in slave interpreter") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        interp = TkCore::INTERP
        slave = interp.create_slave("eval_test", true)

        # Eval something in the slave
        result = interp._eval("interp eval eval_test {expr 2 + 2}")
        raise "expected 4, got \#{result}" unless result.to_s == "4"

        root.destroy
      RUBY
    end
  end

  # Test that TclTkLib.mainloop is global and works with multiple interpreters
  #
  # The Tk event loop is global (Tcl_DoOneEvent processes events for ALL
  # interpreters). TclTkLib.mainloop should not require a single interpreter.
  def test_mainloop_works_with_multiple_interpreters
    assert_tk_test("TclTkLib.mainloop should work with multiple interpreters") do
      <<~RUBY
        require 'tcltklib'

        # Create two independent interpreters
        ip1 = TclTkIp.new
        ip2 = TclTkIp.new

        raise "should have 2 interpreters" unless TclTkIp.instance_count == 2

        # Create a button in each that destroys its own window
        ip1.tcl_eval('button .b -text "ip1" -command "destroy ."')
        ip1.tcl_eval('pack .b')
        ip2.tcl_eval('button .b -text "ip2" -command "destroy ."')
        ip2.tcl_eval('pack .b')

        # Schedule clicks after 100ms to auto-close both windows
        ip1.tcl_eval('after 100 {event generate .b <Button-1>; after 50 {.b invoke}}')
        ip2.tcl_eval('after 150 {event generate .b <Button-1>; after 50 {.b invoke}}')

        # TclTkLib.mainloop should process events for BOTH interpreters
        # This would fail with "Multiple Tcl interpreters exist" if mainloop
        # tried to use TkCore.interp
        TclTkLib.mainloop

        # If we get here, mainloop correctly handled multiple interpreters
      RUBY
    end
  end

  # Test that TclTkLib.thread_timer_ms is a global setting
  def test_thread_timer_ms_is_global
    assert_tk_test("thread_timer_ms should be configurable globally") do
      <<~RUBY
        require 'tcltklib'

        # Check default value
        default = TclTkLib.thread_timer_ms
        raise "default should be 5, got \#{default}" unless default == 5

        # Set to new value
        TclTkLib.thread_timer_ms = 10
        raise "should be 10" unless TclTkLib.thread_timer_ms == 10

        # Set back
        TclTkLib.thread_timer_ms = 5
        raise "should be 5 again" unless TclTkLib.thread_timer_ms == 5
      RUBY
    end
  end

  # Test that TclTkLib.do_one_event is global
  def test_do_one_event_is_global
    assert_tk_test("do_one_event should work without requiring an interpreter") do
      <<~RUBY
        require 'tcltklib'

        # Create an interpreter
        ip = TclTkIp.new

        # Schedule an idle task
        $idle_ran = false
        ip.tcl_eval('after idle {set ::test_var 1}')

        # Process events via global do_one_event
        10.times do
          break unless TclTkLib.do_one_event(TclTkLib::DONT_WAIT)
        end

        # Verify idle task ran
        result = ip.tcl_eval('info exists ::test_var')
        raise "idle task should have run" unless result == "1"

        ip.delete
      RUBY
    end
  end

  # Test that Ruby knows when Tcl deletes an interpreter
  #
  # This tests Tcl_CallWhenDeleted - when Tcl internally deletes an
  # interpreter (via `interp delete`), our Ruby object should know.
  # Without CallWhenDeleted, the Ruby object thinks it's still valid
  # and using it will crash or produce undefined behavior.
  def test_tcl_delete_updates_ruby_state
    assert_tk_test("Ruby should know when Tcl deletes interpreter") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        interp = TkCore::INTERP
        slave = interp.create_slave("delete_test", true)

        # Verify slave works
        raise "slave should not be deleted yet" if slave.deleted?

        # Delete the slave via Tcl (not Ruby) - simulates internal deletion
        interp._eval("interp delete delete_test")

        # Ruby should now know the slave is gone
        # Without Tcl_CallWhenDeleted, slave.deleted? will still be false
        # and trying to use it will crash
        raise "slave.deleted? should be true after Tcl deletes it" unless slave.deleted?

        # Double-check: using deleted interpreter should raise, not crash
        begin
          slave._eval("expr 1 + 1")
          raise "should have raised an error using deleted interpreter"
        rescue TclTkLib::TclError => e
          # Expected - interpreter is deleted
        end

        root.destroy
      RUBY
    end
  end
end
