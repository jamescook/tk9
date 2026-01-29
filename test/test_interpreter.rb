# frozen_string_literal: true

# Tests for TclTkIp - the Tcl/Tk interpreter wrapper
#
# This tests low-level interpreter functionality including:
# - Safe interpreters (sandboxed, restricted commands)
# - Slave interpreters (child interpreters)
# - Interpreter lifecycle (deleted?, delete)
#
# See: https://www.tcl-lang.org/man/tcl/TclCmd/interp.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestInterpreter < Minitest::Test
  include TkTestHelper

  def test_safe_query
    assert_tk_app("Interpreter safe? query", method(:safe_query_app))
  end

  def safe_query_app
    require 'tk'

    errors = []

    # Get the master interpreter (first one created)
    master = TclTkIp.instances.first
    errors << "no master interpreter found" unless master

    # Main interpreter should NOT be safe by default
    errors << "main interp should not be safe" if master.safe?

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_safe_slave
    assert_tk_app("Create safe slave interpreter", method(:create_safe_slave_app))
  end

  def create_safe_slave_app
    require 'tk'

    errors = []

    master = TclTkIp.instances.first

    # Use unique name to avoid conflicts with other tests
    slave_name = "safe_child_#{rand(10000)}"

    # Create a safe slave interpreter
    slave = master.create_slave(slave_name, true)
    errors << "slave should be safe" unless slave.safe?
    errors << "master should not be safe" if master.safe?

    # Safe interpreter should not be able to execute dangerous commands
    # For example, 'exec' should fail
    begin
      slave.tcl_eval('exec echo hello')
      errors << "exec should be forbidden in safe interp"
    rescue TclTkLib::TclError => e
      # Expected - safe interp can't exec
      errors << "wrong error: #{e.message}" unless e.message.include?("invalid command")
    end

    # But normal Tcl commands should work
    result = slave.tcl_eval('expr {1 + 2}')
    errors << "expr failed in safe interp: got '#{result}'" unless result == "3"

    # Clean up
    slave.delete

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_unsafe_slave
    assert_tk_app("Create unsafe slave interpreter", method(:create_unsafe_slave_app))
  end

  def create_unsafe_slave_app
    require 'tk'

    errors = []

    master = TclTkIp.instances.first

    # Use unique names
    name1 = "unsafe_child_#{rand(10000)}"
    name2 = "unsafe_child2_#{rand(10000)}"

    # Create an unsafe slave (default)
    slave = master.create_slave(name1)
    errors << "unsafe slave should not be safe" if slave.safe?

    # Also test explicit false
    slave2 = master.create_slave(name2, false)
    errors << "explicit unsafe slave should not be safe" if slave2.safe?

    # Clean up
    slave.delete
    slave2.delete

    raise errors.join("\n") unless errors.empty?
  end

  def test_deleted_query
    assert_tk_app("Interpreter deleted? query", method(:deleted_query_app))
  end

  def deleted_query_app
    require 'tk'

    errors = []

    master = TclTkIp.instances.first

    # Create a slave we can delete
    slave_name = "to_delete_#{rand(10000)}"
    slave = master.create_slave(slave_name)
    errors << "new slave should not be deleted" if slave.deleted?

    # Delete it
    slave.delete
    errors << "deleted slave should report deleted?" unless slave.deleted?

    raise errors.join("\n") unless errors.empty?
  end
end
