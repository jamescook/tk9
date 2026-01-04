# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestBridge < Minitest::Test
  include TkTestHelper

  def test_basic_creation
    assert_tk_test("Bridge basic creation") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        raise "Expected Tk::Bridge" unless bridge.is_a?(Tk::Bridge)
        raise "Expected TclTkIp" unless bridge.interp.is_a?(TclTkIp)
      RUBY
    end
  end

  def test_default_singleton
    assert_tk_test("Bridge default singleton") do
      <<~RUBY
        require 'tk/bridge'
        bridge1 = Tk::Bridge.default
        bridge2 = Tk::Bridge.default
        raise "default should return same instance" unless bridge1.equal?(bridge2)
      RUBY
    end
  end

  def test_reset_default
    assert_tk_test("Bridge reset_default") do
      <<~RUBY
        require 'tk/bridge'
        bridge1 = Tk::Bridge.default
        Tk::Bridge.reset_default!
        bridge2 = Tk::Bridge.default
        raise "reset should create new instance" if bridge1.equal?(bridge2)
      RUBY
    end
  end

  def test_eval_tcl
    assert_tk_test("Bridge eval") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        result = bridge.eval("expr {1 + 2}")
        raise "Expected '3', got \#{result.inspect}" unless result == "3"
      RUBY
    end
  end

  def test_invoke_tcl
    assert_tk_test("Bridge invoke") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        result = bridge.invoke("expr", "1 + 2")
        raise "Expected '3', got \#{result.inspect}" unless result == "3"
      RUBY
    end
  end

  def test_version_info
    assert_tk_test("Bridge version info") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        raise "tcl_version doesn't match" unless bridge.tcl_version =~ /\\d+\\.\\d+/
        raise "tk_version doesn't match" unless bridge.tk_version =~ /\\d+\\.\\d+/
      RUBY
    end
  end

  def test_window_exists
    assert_tk_test("Bridge window_exists?") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        raise "Root window should exist" unless bridge.window_exists?(".")
        raise "Nonexistent window should not exist" if bridge.window_exists?(".nonexistent")
      RUBY
    end
  end

  def test_register_callback
    assert_tk_test("Bridge register_callback") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        id = bridge.register_callback { }
        raise "Expected cb_N format, got \#{id.inspect}" unless id =~ /^cb_\\d+$/
      RUBY
    end
  end

  def test_tcl_callback_command
    assert_tk_test("Bridge tcl_callback_command") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        id = bridge.register_callback { }

        cmd = bridge.tcl_callback_command(id)
        raise "Expected cmd to include id" unless cmd.include?(id)
        raise "Expected cmd to include lappend" unless cmd.include?("lappend")

        cmd_with_subs = bridge.tcl_callback_command(id, "%W", "%x")
        raise "Expected cmd to include %W" unless cmd_with_subs.include?("%W")
        raise "Expected cmd to include %x" unless cmd_with_subs.include?("%x")
      RUBY
    end
  end

  def test_callback_dispatch
    assert_tk_test("Bridge callback dispatch") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        results = []

        id = bridge.register_callback { |*args| results << args }

        # Simulate what Tcl does: append to the queue variable
        bridge.eval("lappend \#{Tk::Bridge::CALLBACK_QUEUE_VAR} [list \#{id} arg1 arg2]")

        # Dispatch should process the queue
        bridge.dispatch_pending_callbacks

        expected = [["arg1", "arg2"]]
        raise "Expected \#{expected.inspect}, got \#{results.inspect}" unless results == expected
      RUBY
    end
  end

  def test_multiple_bridges_isolated
    assert_tk_test("Multiple bridges are isolated") do
      <<~RUBY
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
      RUBY
    end
  end

  def test_unregister_callback
    assert_tk_test("Bridge unregister_callback") do
      <<~RUBY
        require 'tk/bridge'
        bridge = Tk::Bridge.new
        called = false
        id = bridge.register_callback { called = true }

        bridge.unregister_callback(id)

        # Queue a call to the unregistered callback
        bridge.eval("lappend \#{Tk::Bridge::CALLBACK_QUEUE_VAR} [list \#{id}]")
        bridge.dispatch_pending_callbacks

        raise "Unregistered callback should not be called" if called
      RUBY
    end
  end
end
