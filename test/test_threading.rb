# frozen_string_literal: true

# Tests for Ruby threading + Tk event loop interaction
#
# Key C functions exercised:
#   - lib_eventloop_core / lib_eventloop_launcher (Tk.update, TkTimer)
#   - ip_ruby_cmd (widget callbacks - Tcl calling Ruby)
#   - tcl_protect_core (exception handling)
#   - ip_eval_real, tk_funcall (Tcl eval round-trips)

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestThreading < Minitest::Test
  include TkTestHelper

  # TkTimer fires correctly
  def test_tktimer_fires
    assert_tk_app("TkTimer callback should fire", method(:app_tktimer_fires))
  end

  def app_tktimer_fires
    require 'tk'

    timer_fired = false
    timer = TkTimer.new(50, 1) { timer_fired = true }
    timer.start

    # Run event loop briefly
    start = Time.now
    while Time.now - start < 0.3
      Tk.update
      sleep 0.01
    end

    raise "TkTimer callback did not fire" unless timer_fired
  end

  # Ruby Thread runs alongside Tk
  def test_ruby_thread_alongside_tk
    assert_tk_app("Ruby Thread should execute alongside Tk", method(:app_ruby_thread_alongside_tk))
  end

  def app_ruby_thread_alongside_tk
    require 'tk'

    thread_result = nil
    t = Thread.new { thread_result = 42 }

    start = Time.now
    while Time.now - start < 0.3
      Tk.update
      sleep 0.01
    end

    t.join(1)
    raise "Ruby Thread did not execute, got #{thread_result.inspect}" unless thread_result == 42
  end

  # Tk.sleep in a thread completes
  def test_tk_sleep_in_thread
    assert_tk_app("Tk.sleep in a thread should complete", method(:app_tk_sleep_in_thread))
  end

  def app_tk_sleep_in_thread
    require 'tk'

    sleep_done = false
    Thread.new { Tk.sleep(50); sleep_done = true }

    start = Time.now
    while Time.now - start < 0.3
      Tk.update
      sleep 0.01
    end

    raise "Tk.sleep in thread did not complete" unless sleep_done
  end

  # Tk.wakeup interrupts Tk.sleep early
  def test_tk_wakeup_interrupts_sleep
    assert_tk_subprocess("Tk.wakeup should interrupt Tk.sleep") do
      <<~'RUBY'
        require 'tk'

        # Use a named variable so wakeup can target it
        sleep_var = TkVariable.new
        sleep_start = Time.now

        # Schedule wakeup after 100ms using Tk's after
        TkAfter.new(100, 1) { Tk.wakeup(sleep_var) }.start

        # Start a long sleep (5 seconds) - should be interrupted by wakeup
        Tk.sleep(5000, sleep_var)

        elapsed = Time.now - sleep_start
        raise "Sleep took too long (#{elapsed}s), wakeup didn't work" if elapsed > 1.0
        raise "Sleep was too short (#{elapsed}s), wakeup fired too early" if elapsed < 0.05
      RUBY
    end
  end

  # Multiple threads invoking Tk widget callbacks
  def test_threads_invoking_widget_callbacks
    assert_tk_app("Threads should be able to invoke widget callbacks", method(:app_threads_invoking_widget_callbacks))
  end

  def app_threads_invoking_widget_callbacks
    require 'tk'

    counter = 0
    mutex = Mutex.new

    # Button callback increments counter
    btn = TkButton.new(root) do
      command { mutex.synchronize { counter += 1 } }
    end

    # 3 threads each invoke the button 5 times
    threads = 3.times.map do
      Thread.new do
        5.times do
          btn.invoke
          sleep 0.01
        end
      end
    end

    start = Time.now
    while Time.now - start < 0.5
      Tk.update
      sleep 0.01
    end

    threads.each { |th| th.join(1) }
    raise "Expected counter=15, got #{counter}" unless counter == 15
  end

  # TkVariable from thread
  def test_tkvariable_from_thread
    assert_tk_app("TkVariable should be modifiable from threads", method(:app_tkvariable_from_thread))
  end

  def app_tkvariable_from_thread
    require 'tk'

    var = TkVariable.new(0)
    Thread.new do
      5.times do
        var.numeric += 1
        sleep 0.01
      end
    end

    start = Time.now
    while Time.now - start < 0.3
      Tk.update
      sleep 0.01
    end

    raise "TkVariable not modified, got #{var.numeric}" unless var.numeric >= 1
  end

  # Widget callback (exercises ip_ruby_cmd - Tcl calling Ruby)
  def test_widget_callback
    assert_tk_app("Widget callback should fire via ip_ruby_cmd", method(:app_widget_callback))
  end

  def app_widget_callback
    require 'tk'

    callback_fired = false
    btn = TkButton.new(root) { command { callback_fired = true } }
    btn.invoke

    start = Time.now
    while Time.now - start < 0.1
      Tk.update
      sleep 0.01
    end

    raise "Widget callback did not fire" unless callback_fired
  end

  # Callback spawning a thread
  def test_callback_spawns_thread
    assert_tk_app("Callback should be able to spawn threads", method(:app_callback_spawns_thread))
  end

  def app_callback_spawns_thread
    require 'tk'

    callback_thread_result = nil
    btn = TkButton.new(root) do
      command { Thread.new { callback_thread_result = "from_callback" }.join }
    end
    btn.invoke

    start = Time.now
    while Time.now - start < 0.1
      Tk.update
      sleep 0.01
    end

    raise "Thread in callback failed, got #{callback_thread_result.inspect}" unless callback_thread_result == "from_callback"
  end

  # Exception in callback propagates (exercises tcl_protect_core)
  def test_exception_in_callback
    assert_tk_app("Exception in callback should propagate through tcl_protect_core", method(:app_exception_in_callback))
  end

  def app_exception_in_callback
    require 'tk'

    exception_callback_ran = false
    exception_caught = false

    btn = TkButton.new(root) do
      command do
        exception_callback_ran = true
        raise "callback_test_error"
      end
    end

    begin
      btn.invoke
    rescue => e
      exception_caught = e.message.include?("callback_test_error")
    end

    start = Time.now
    while Time.now - start < 0.1
      Tk.update
      sleep 0.01
    end

    raise "Exception callback did not run" unless exception_callback_ran
    raise "Exception did not propagate correctly" unless exception_caught
  end

  # Round-trip Tcl eval (exercises ip_eval_real)
  def test_tcl_eval_roundtrip
    assert_tk_app("Tcl eval should return correct result", method(:app_tcl_eval_roundtrip))
  end

  def app_tcl_eval_roundtrip
    require 'tk'

    interp = TkCore::INTERP
    result = interp._eval("expr {2 + 2}")
    raise "Expected '4', got '#{result}'" unless result == "4"
  end

  # Round-trip with string data
  def test_tcl_eval_string_roundtrip
    assert_tk_app("Tcl variable round-trip should preserve string", method(:app_tcl_eval_string_roundtrip))
  end

  def app_tcl_eval_string_roundtrip
    require 'tk'

    interp = TkCore::INTERP
    interp._eval('set testvar "hello from tcl"')
    result = interp._eval('set testvar')
    raise "Expected 'hello from tcl', got '#{result}'" unless result == "hello from tcl"
  end

  # Thread calling Tcl eval (exercises tk_funcall cross-thread path)
  def test_thread_tcl_eval
    assert_tk_app("Thread should be able to call Tcl eval", method(:app_thread_tcl_eval))
  end

  def app_thread_tcl_eval
    require 'tk'

    interp = TkCore::INTERP
    thread_eval_result = nil

    t = Thread.new do
      thread_eval_result = interp._eval("expr {3 * 7}")
    end

    start = Time.now
    while Time.now - start < 0.2
      Tk.update
      sleep 0.01
    end

    t.join(1)
    raise "Expected '21', got '#{thread_eval_result}'" unless thread_eval_result == "21"
  end

  # TkCore.on_main_thread from background thread
  def test_on_main_thread_from_background
    assert_tk_app("on_main_thread should work from background thread", method(:app_on_main_thread_from_background))
  end

  def app_on_main_thread_from_background
    require 'tk'

    # DEBUG: Show interpreter count before test
    count = TclTkIp.instance_count
    instances = TclTkIp.instances.map { |i| "#{i.object_id}(deleted=#{i.deleted?})" }
    STDERR.puts "\n=== DEBUG: #{count} interpreters: #{instances.join(', ')} ==="
    STDERR.flush

    result = nil
    error = nil

    t = Thread.new do
      begin
        result = TkCore.on_main_thread { 6 * 7 }
      rescue => e
        error = e
      end
    end

    # Pump event loop so the queued work gets processed
    start = Time.now
    while Time.now - start < 0.3
      Tk.update
      sleep 0.01
    end

    t.join(1)
    raise "on_main_thread raised: #{error}" if error
    raise "Expected 42, got #{result.inspect}" unless result == 42
  end

  # TkCore.on_main_thread from main thread (should execute immediately)
  def test_on_main_thread_from_main
    assert_tk_app("on_main_thread should execute immediately on main thread", method(:app_on_main_thread_from_main))
  end

  def app_on_main_thread_from_main
    require 'tk'

    # Verify we're on main thread
    raise "Test not running on main thread" unless Thread.current == Thread.main

    # Should execute immediately without needing event loop pump
    result = TkCore.on_main_thread { "immediate" }
    raise "Expected 'immediate', got #{result.inspect}" unless result == "immediate"

    # Should propagate exceptions
    exception_caught = false
    begin
      TkCore.on_main_thread { raise "test_error" }
    rescue => e
      exception_caught = e.message.include?("test_error")
    end
    raise "Exception not propagated from on_main_thread" unless exception_caught
  end

  # TkCore.on_main_thread propagates exceptions from background thread
  def test_on_main_thread_exception_propagation
    assert_tk_app("on_main_thread should propagate exceptions to caller", method(:app_on_main_thread_exception_propagation))
  end

  def app_on_main_thread_exception_propagation
    require 'tk'

    # DEBUG: Show interpreter count before test
    count = TclTkIp.instance_count
    instances = TclTkIp.instances.map { |i| "#{i.object_id}(deleted=#{i.deleted?})" }
    STDERR.puts "\n=== DEBUG: #{count} interpreters: #{instances.join(', ')} ==="
    STDERR.flush

    caught_exception = nil

    t = Thread.new do
      begin
        TkCore.on_main_thread { raise "background_error" }
      rescue => e
        caught_exception = e
      end
    end

    start = Time.now
    while Time.now - start < 0.3
      Tk.update
      sleep 0.01
    end

    t.join(1)
    raise "Exception not caught in background thread" unless caught_exception
    raise "Wrong exception: #{caught_exception.message}" unless caught_exception.message.include?("background_error")
  end
end
