# frozen_string_literal: true

# Tests for Ruby threading + Tk event loop interaction
#
# Key C functions exercised:
#   - lib_eventloop_core / lib_eventloop_launcher (Tk.update, TkTimer)
#   - ip_ruby_cmd (widget callbacks - Tcl calling Ruby)
#   - tcl_protect_core (exception handling)
#   - ip_eval_real, tk_funcall (Tcl eval round-trips)

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require_relative 'tk_test_helper'

class TestThreading < Minitest::Test
  include TkTestHelper

  # TkTimer fires correctly
  def test_tktimer_fires
    assert_tk_test("TkTimer callback should fire") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

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
        root.destroy
      RUBY
    end
  end

  # Ruby Thread runs alongside Tk
  def test_ruby_thread_alongside_tk
    assert_tk_test("Ruby Thread should execute alongside Tk") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        thread_result = nil
        t = Thread.new { thread_result = 42 }

        start = Time.now
        while Time.now - start < 0.3
          Tk.update
          sleep 0.01
        end

        t.join(1)
        raise "Ruby Thread did not execute, got \#{thread_result.inspect}" unless thread_result == 42
        root.destroy
      RUBY
    end
  end

  # Tk.sleep in a thread completes
  def test_tk_sleep_in_thread
    assert_tk_test("Tk.sleep in a thread should complete") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        sleep_done = false
        Thread.new { Tk.sleep(50); sleep_done = true }

        start = Time.now
        while Time.now - start < 0.3
          Tk.update
          sleep 0.01
        end

        raise "Tk.sleep in thread did not complete" unless sleep_done
        root.destroy
      RUBY
    end
  end

  # Multiple threads invoking Tk widget callbacks
  def test_threads_invoking_widget_callbacks
    assert_tk_test("Threads should be able to invoke widget callbacks") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

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
        raise "Expected counter=15, got \#{counter}" unless counter == 15
        root.destroy
      RUBY
    end
  end

  # TkVariable from thread
  def test_tkvariable_from_thread
    assert_tk_test("TkVariable should be modifiable from threads") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

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

        raise "TkVariable not modified, got \#{var.numeric}" unless var.numeric >= 1
        root.destroy
      RUBY
    end
  end

  # Widget callback (exercises ip_ruby_cmd - Tcl calling Ruby)
  def test_widget_callback
    assert_tk_test("Widget callback should fire via ip_ruby_cmd") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        callback_fired = false
        btn = TkButton.new(root) { command { callback_fired = true } }
        btn.invoke

        start = Time.now
        while Time.now - start < 0.1
          Tk.update
          sleep 0.01
        end

        raise "Widget callback did not fire" unless callback_fired
        root.destroy
      RUBY
    end
  end

  # Callback spawning a thread
  def test_callback_spawns_thread
    assert_tk_test("Callback should be able to spawn threads") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

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

        raise "Thread in callback failed, got \#{callback_thread_result.inspect}" unless callback_thread_result == "from_callback"
        root.destroy
      RUBY
    end
  end

  # Exception in callback propagates (exercises tcl_protect_core)
  def test_exception_in_callback
    assert_tk_test("Exception in callback should propagate through tcl_protect_core") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

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
        root.destroy
      RUBY
    end
  end

  # Round-trip Tcl eval (exercises ip_eval_real)
  def test_tcl_eval_roundtrip
    assert_tk_test("Tcl eval should return correct result") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        interp = TkCore::INTERP
        result = interp._eval("expr {2 + 2}")
        raise "Expected '4', got '\#{result}'" unless result == "4"

        root.destroy
      RUBY
    end
  end

  # Round-trip with string data
  def test_tcl_eval_string_roundtrip
    assert_tk_test("Tcl variable round-trip should preserve string") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

        interp = TkCore::INTERP
        interp._eval('set testvar "hello from tcl"')
        result = interp._eval('set testvar')
        raise "Expected 'hello from tcl', got '\#{result}'" unless result == "hello from tcl"

        root.destroy
      RUBY
    end
  end

  # Thread calling Tcl eval (exercises tk_funcall cross-thread path)
  def test_thread_tcl_eval
    assert_tk_test("Thread should be able to call Tcl eval") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }

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
        raise "Expected '21', got '\#{thread_eval_result}'" unless thread_eval_result == "21"

        root.destroy
      RUBY
    end
  end
end
