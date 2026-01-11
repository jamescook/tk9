# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestBridge < Minitest::Test
  include TkTestHelper

  def test_basic_creation
    assert_tk_app("Bridge basic creation", method(:app_basic_creation))
  end

  def app_basic_creation
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    raise "Expected Tk::Bridge" unless bridge.is_a?(Tk::Bridge)
    raise "Expected TclTkIp" unless bridge.interp.is_a?(TclTkIp)
  end

  def test_default_singleton
    assert_tk_app("Bridge default singleton", method(:app_default_singleton))
  end

  def app_default_singleton
    require 'tk/bridge'
    bridge1 = Tk::Bridge.default
    bridge2 = Tk::Bridge.default
    raise "default should return same instance" unless bridge1.equal?(bridge2)
  end

  def test_reset_default
    assert_tk_app("Bridge reset_default", method(:app_reset_default))
  end

  def app_reset_default
    require 'tk/bridge'
    bridge1 = Tk::Bridge.default
    Tk::Bridge.reset_default!
    bridge2 = Tk::Bridge.default
    raise "reset should create new instance" if bridge1.equal?(bridge2)
  end

  def test_eval_tcl
    assert_tk_app("Bridge eval", method(:app_eval_tcl))
  end

  def app_eval_tcl
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    result = bridge.eval("expr {1 + 2}")
    raise "Expected '3', got #{result.inspect}" unless result == "3"
  end

  def test_invoke_tcl
    assert_tk_app("Bridge invoke", method(:app_invoke_tcl))
  end

  def app_invoke_tcl
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    result = bridge.invoke("expr", "1 + 2")
    raise "Expected '3', got #{result.inspect}" unless result == "3"
  end

  def test_version_info
    assert_tk_app("Bridge version info", method(:app_version_info))
  end

  def app_version_info
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    raise "tcl_version doesn't match" unless bridge.tcl_version =~ /\d+\.\d+/
    raise "tk_version doesn't match" unless bridge.tk_version =~ /\d+\.\d+/
  end

  def test_window_exists
    assert_tk_app("Bridge window_exists?", method(:app_window_exists))
  end

  def app_window_exists
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    raise "Root window should exist" unless bridge.window_exists?(".")
    raise "Nonexistent window should not exist" if bridge.window_exists?(".nonexistent")
  end

  def test_register_callback
    assert_tk_app("Bridge register_callback", method(:app_register_callback))
  end

  def app_register_callback
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    id = bridge.register_callback { }
    raise "Expected cb_N format, got #{id.inspect}" unless id =~ /^cb_\d+$/
  end

  def test_tcl_callback_command
    assert_tk_app("Bridge tcl_callback_command", method(:app_tcl_callback_command))
  end

  def app_tcl_callback_command
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    id = bridge.register_callback { }

    cmd = bridge.tcl_callback_command(id)
    raise "Expected cmd to include id" unless cmd.include?(id)
    raise "Expected cmd to include lappend" unless cmd.include?("lappend")

    cmd_with_subs = bridge.tcl_callback_command(id, "%W", "%x")
    raise "Expected cmd to include %W" unless cmd_with_subs.include?("%W")
    raise "Expected cmd to include %x" unless cmd_with_subs.include?("%x")
  end

  def test_callback_dispatch
    assert_tk_app("Bridge callback dispatch", method(:app_callback_dispatch))
  end

  def app_callback_dispatch
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    results = []

    id = bridge.register_callback { |*args| results << args }

    # Simulate what Tcl does: append to the queue variable
    bridge.eval("lappend #{Tk::Bridge::CALLBACK_QUEUE_VAR} [list #{id} arg1 arg2]")

    # Dispatch should process the queue
    bridge.dispatch_pending_callbacks

    expected = [["arg1", "arg2"]]
    raise "Expected #{expected.inspect}, got #{results.inspect}" unless results == expected
  end

  def test_multiple_bridges_isolated
    assert_tk_app("Multiple bridges are isolated", method(:app_multiple_bridges_isolated))
  end

  def app_multiple_bridges_isolated
    require 'tk/bridge'
    bridge1 = Tk::Bridge.new
    bridge2 = Tk::Bridge.new

    # Each bridge has its own interpreter
    raise "Interpreters should be different" if bridge1.interp.equal?(bridge2.interp)

    # Set variable in one, shouldn't affect other
    bridge1.eval("set myvar 1")
    bridge2.eval("set myvar 2")

    raise "bridge1 myvar wrong" unless bridge1.eval("set myvar") == "1"
    raise "bridge2 myvar wrong" unless bridge2.eval("set myvar") == "2"
  end

  def test_unregister_callback
    assert_tk_app("Bridge unregister_callback", method(:app_unregister_callback))
  end

  def app_unregister_callback
    require 'tk/bridge'
    bridge = Tk::Bridge.new
    called = false
    id = bridge.register_callback { called = true }

    bridge.unregister_callback(id)

    # Queue a call to the unregistered callback
    bridge.eval("lappend #{Tk::Bridge::CALLBACK_QUEUE_VAR} [list #{id}]")
    bridge.dispatch_pending_callbacks

    raise "Unregistered callback should not be called" if called
  end
end
