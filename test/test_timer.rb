# frozen_string_literal: true

# Tests for TkTimer - Tcl's "after" command wrapper
#
# TkTimer schedules callbacks to run after a delay. It supports:
# - One-shot timers (run once after delay)
# - Repeating timers (run N times or forever)
# - Multiple procs in sequence
# - Dynamic intervals (proc that returns delay)
#
# See: https://www.tcl-lang.org/man/tcl/TclCmd/after.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTimer < Minitest::Test
  include TkTestHelper

  # ===========================================
  # Basic lifecycle: create, start, stop
  # ===========================================

  def test_timer_create
    assert_tk_app("Timer create", method(:timer_create_app))
  end

  def timer_create_app
    require 'tk'
    require 'tk/timer'

    errors = []

    # Create a timer with interval and proc
    called = false
    timer = TkTimer.new(100, 1, proc { called = true })

    errors << "should not be running before start" if timer.running?
    errors << "after_id should be nil before start" if timer.after_id

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_start_and_callback
    assert_tk_app("Timer start and callback", method(:timer_start_callback_app))
  end

  def timer_start_callback_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(50, 1, proc { call_count += 1 })

    timer.start
    errors << "should be running after start" unless timer.running?
    errors << "after_id should exist after start" unless timer.after_id

    # Process events until callback fires
    start_time = Time.now
    while call_count == 0 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "callback should have fired, count=#{call_count}" unless call_count == 1

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_cancel
    assert_tk_app("Timer cancel", method(:timer_cancel_app))
  end

  def timer_cancel_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(500, 1, proc { call_count += 1 })

    timer.start
    errors << "should be running" unless timer.running?

    timer.cancel
    errors << "should not be running after cancel" if timer.running?
    errors << "after_id should be nil after cancel" if timer.after_id

    # Process some events - callback should NOT fire
    10.times do
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "callback should not have fired after cancel" unless call_count == 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_stop_alias
    assert_tk_app("Timer stop alias", method(:timer_stop_alias_app))
  end

  def timer_stop_alias_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(500, 1, proc { })
    timer.start
    timer.stop  # alias for cancel

    errors << "stop should cancel timer" if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Class method: TkTimer.start
  # ===========================================

  def test_timer_class_start
    assert_tk_app("Timer class start", method(:timer_class_start_app))
  end

  def timer_class_start_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.start(50, 1, proc { call_count += 1 })

    errors << "TkTimer.start should return running timer" unless timer.running?

    # Wait for callback
    start_time = Time.now
    while call_count == 0 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "callback should have fired" unless call_count == 1

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # TkAfter alias
  # ===========================================

  def test_tkafter_alias
    assert_tk_app("TkAfter alias", method(:tkafter_alias_app))
  end

  def tkafter_alias_app
    require 'tk'
    require 'tk/timer'

    errors = []

    errors << "TkAfter should be alias for TkTimer" unless TkAfter == TkTimer

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Looping: run callback multiple times
  # ===========================================

  def test_timer_loop_count
    assert_tk_app("Timer loop count", method(:timer_loop_count_app))
  end

  def timer_loop_count_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    # Run 3 times with 30ms interval
    timer = TkTimer.new(30, 3, proc { call_count += 1 })
    timer.start

    # Wait for all callbacks
    start_time = Time.now
    while call_count < 3 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "expected 3 calls, got #{call_count}" unless call_count == 3
    errors << "timer should not be running after loop completes" if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_loop_rest
    assert_tk_app("Timer loop_rest", method(:timer_loop_rest_app))
  end

  def timer_loop_rest_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(30, 5, proc { call_count += 1 })
    timer.start

    # Wait for first callback
    start_time = Time.now
    while call_count < 1 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # loop_rest should decrease as callbacks fire
    rest = timer.loop_rest
    errors << "loop_rest should be <= 4 after first call, got #{rest}" if rest > 4

    timer.cancel

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Status methods
  # ===========================================

  def test_timer_running
    assert_tk_app("Timer running?", method(:timer_running_app))
  end

  def timer_running_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(100, 1, proc { })

    errors << "should not be running before start" if timer.running?

    timer.start
    errors << "should be running after start" unless timer.running?

    timer.cancel
    errors << "should not be running after cancel" if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_current_status
    assert_tk_app("Timer current_status", method(:timer_current_status_app))
  end

  def timer_current_status_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(100, 3, proc { })
    timer.start

    status = timer.current_status
    # Returns: [running, current_sleep, current_proc, current_args, do_loop, cancel_on_exception]
    errors << "current_status should be array" unless status.is_a?(Array)
    errors << "current_status[0] should be running state" unless status[0] == true

    timer.cancel

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_get_procs
    assert_tk_app("Timer get_procs", method(:timer_get_procs_app))
  end

  def timer_get_procs_app
    require 'tk'
    require 'tk/timer'

    errors = []

    my_proc = proc { }
    timer = TkTimer.new(100, 2, my_proc)

    procs = timer.get_procs
    # Returns: [init_sleep, init_proc, init_args, sleep_time, loop_exec, loop_proc]
    errors << "get_procs should be array" unless procs.is_a?(Array)
    errors << "get_procs should have 6 elements, got #{procs.size}" unless procs.size == 6

    # sleep_time is index 3
    errors << "sleep_time should be 100" unless procs[3] == 100

    # loop_exec is index 4
    errors << "loop_exec should be 2" unless procs[4] == 2

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Return value from callback
  # ===========================================

  def test_timer_return_value
    assert_tk_app("Timer return_value", method(:timer_return_value_app))
  end

  def timer_return_value_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(30, 1, proc { "hello from timer" })
    timer.start

    # Wait for callback
    start_time = Time.now
    while timer.running? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "return_value should be 'hello from timer'" unless timer.return_value == "hello from timer"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Configuration: set_procs, add_procs, set_interval
  # ===========================================

  def test_timer_set_interval
    assert_tk_app("Timer set_interval", method(:timer_set_interval_app))
  end

  def timer_set_interval_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(100, 1, proc { })
    timer.set_interval(200)

    procs = timer.get_procs
    errors << "interval should be 200, got #{procs[3]}" unless procs[3] == 200

    # Can also set to 'idle'
    timer.set_interval('idle')
    procs = timer.get_procs
    errors << "interval should be 'idle'" unless procs[3] == 'idle'

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_add_procs
    assert_tk_app("Timer add_procs", method(:timer_add_procs_app))
  end

  def timer_add_procs_app
    require 'tk'
    require 'tk/timer'

    errors = []

    results = []
    timer = TkTimer.new(30, 1, proc { results << "first" })
    timer.add_procs(proc { results << "second" })
    timer.start

    # Wait for both callbacks
    start_time = Time.now
    while results.size < 2 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "expected ['first', 'second'], got #{results.inspect}" unless results == ["first", "second"]

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_delete_at
    assert_tk_app("Timer delete_at", method(:timer_delete_at_app))
  end

  def timer_delete_at_app
    require 'tk'
    require 'tk/timer'

    errors = []

    results = []
    proc1 = proc { results << "first" }
    proc2 = proc { results << "second" }
    proc3 = proc { results << "third" }

    timer = TkTimer.new(30, 1, proc1, proc2, proc3)

    # Delete the middle proc
    timer.delete_at(1)

    timer.start

    # Wait for callbacks
    start_time = Time.now
    while results.size < 2 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # Should skip "second"
    errors << "expected ['first', 'third'], got #{results.inspect}" unless results == ["first", "third"]

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # at_end callback
  # ===========================================

  def test_timer_at_end
    assert_tk_app("Timer at_end", method(:timer_at_end_app))
  end

  def timer_at_end_app
    require 'tk'
    require 'tk/timer'

    errors = []

    ended = false
    timer = TkTimer.new(30, 2, proc { })
    timer.at_end { ended = true }
    timer.start

    # Wait for timer to complete
    start_time = Time.now
    while timer.running? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "at_end callback should have been called" unless ended

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_at_end_on_cancel
    assert_tk_app("Timer at_end on cancel", method(:timer_at_end_on_cancel_app))
  end

  def timer_at_end_on_cancel_app
    require 'tk'
    require 'tk/timer'

    errors = []

    ended = false
    timer = TkTimer.new(500, 5, proc { })
    timer.at_end { ended = true }
    timer.start
    timer.cancel

    errors << "at_end should be called on cancel too" unless ended

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # cancel_on_exception
  # ===========================================

  def test_timer_cancel_on_exception
    assert_tk_app("Timer cancel_on_exception", method(:timer_cancel_on_exception_app))
  end

  def timer_cancel_on_exception_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(100, 1, proc { })

    # Default should include NameError and RuntimeError
    exc = timer.cancel_on_exception?
    errors << "default should include NameError" unless exc.include?(NameError)
    errors << "default should include RuntimeError" unless exc.include?(RuntimeError)

    # Can set to false to disable
    timer.cancel_on_exception = false
    errors << "should be false after setting" if timer.cancel_on_exception?

    # Can set to custom array
    timer.cancel_on_exception = [ArgumentError]
    exc = timer.cancel_on_exception?
    errors << "should be custom array" unless exc == [ArgumentError]

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # restart - cancel and start again
  # ===========================================

  def test_timer_restart
    assert_tk_app("Timer restart", method(:timer_restart_app))
  end

  def timer_restart_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(30, 2, proc { call_count += 1 })
    timer.start

    # Wait for first callback
    start_time = Time.now
    while call_count < 1 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # Restart - should reset loop counter
    timer.restart

    errors << "should be running after restart" unless timer.running?

    # Wait for both callbacks again
    start_time = Time.now
    while call_count < 3 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # Should have at least 3 calls (1 before restart + 2 after)
    errors << "expected at least 3 calls after restart, got #{call_count}" if call_count < 3

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_restart_with_new_params
    assert_tk_app("Timer restart with new params", method(:timer_restart_new_params_app))
  end

  def timer_restart_new_params_app
    require 'tk'
    require 'tk/timer'

    errors = []

    results = []
    timer = TkTimer.new(500, 1, proc { results << "original" })
    timer.start

    # Restart with different initial proc
    timer.restart(30, proc { results << "new" })

    # Wait for callback
    start_time = Time.now
    while results.empty? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "expected 'new' callback, got #{results.inspect}" unless results.include?("new")

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # continue - resume after cancel
  # ===========================================

  def test_timer_continue
    assert_tk_app("Timer continue", method(:timer_continue_app))
  end

  def timer_continue_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(30, 3, proc { call_count += 1 })
    timer.start

    # Wait for first callback
    start_time = Time.now
    while call_count < 1 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # Cancel mid-loop
    timer.cancel
    errors << "should not be running after cancel" if timer.running?

    count_at_cancel = call_count

    # Continue where we left off
    timer.continue

    errors << "should be running after continue" unless timer.running?

    # Wait for more callbacks
    start_time = Time.now
    while call_count <= count_at_cancel && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "should have more calls after continue" unless call_count > count_at_cancel

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_continue_with_wait
    assert_tk_app("Timer continue with wait override", method(:timer_continue_wait_app))
  end

  def timer_continue_wait_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(500, 2, proc { call_count += 1 })
    timer.start
    timer.cancel

    # Continue with shorter wait time
    timer.continue(30)

    errors << "should be running after continue" unless timer.running?

    # Should fire quickly with 30ms wait
    start_time = Time.now
    while call_count < 1 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "callback should fire with overridden wait time" unless call_count >= 1

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # skip - skip current callback, go to next
  # ===========================================

  def test_timer_skip
    assert_tk_app("Timer skip", method(:timer_skip_app))
  end

  def timer_skip_app
    require 'tk'
    require 'tk/timer'

    errors = []

    results = []
    proc1 = proc { results << "first" }
    proc2 = proc { results << "second" }
    proc3 = proc { results << "third" }

    timer = TkTimer.new(30, 1, proc1, proc2, proc3)
    timer.start

    # Wait briefly then skip
    sleep 0.01
    Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)

    # Skip while running
    if timer.running?
      timer.skip
      errors << "should still be running after skip" unless timer.running?
    end

    # Wait for remaining callbacks
    start_time = Time.now
    while timer.running? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # At least one callback should have been skipped or sequence changed
    errors << "skip should have affected callback sequence" if results.size >= 3 && results == ["first", "second", "third"]

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # reset - reset position to beginning
  # ===========================================

  def test_timer_reset
    assert_tk_app("Timer reset", method(:timer_reset_app))
  end

  def timer_reset_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkTimer.new(30, 3, proc { call_count += 1 })
    timer.start

    # Wait for first callback
    start_time = Time.now
    while call_count < 1 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # Reset should restart from beginning
    timer.reset

    # current_pos should be back to 0
    status = timer.current_status
    # status[4] is do_loop (remaining loops)

    timer.cancel if timer.running?

    # Reset should have been called without error
    errors << "reset should complete without error" if call_count < 1

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # set_start_proc - configure initial callback
  # ===========================================

  def test_timer_set_start_proc
    assert_tk_app("Timer set_start_proc", method(:timer_set_start_proc_app))
  end

  def timer_set_start_proc_app
    require 'tk'
    require 'tk/timer'

    errors = []

    results = []
    timer = TkTimer.new(30, 1, proc { results << "loop" })
    timer.start

    # Wait for loop callback
    start_time = Time.now
    while results.empty? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # set_start_proc configures what restart() will use when called without args
    # Must be called AFTER start (which clears init values)
    timer.set_start_proc(30, proc { results << "init" })

    # restart() without args uses the stored init values
    timer.restart

    # Wait for init callback
    start_time = Time.now
    while !results.include?("init") && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "restart should use set_start_proc's init, got #{results.inspect}" unless results.include?("init")

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # info - get timer info
  # ===========================================

  def test_timer_instance_info
    assert_tk_app("Timer instance info", method(:timer_instance_info_app))
  end

  def timer_instance_info_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(500, 1, proc { })

    # Before start, info should be nil
    errors << "info should be nil before start" unless timer.info.nil?

    timer.start

    # After start, info should return array with timer and type
    info = timer.info
    errors << "info should be array after start" unless info.is_a?(Array)
    errors << "info[0] should be the timer object" unless info[0] == timer
    errors << "info[1] should be 'timer'" unless info[1] == 'timer'

    timer.cancel

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_class_info
    assert_tk_app("Timer class info", method(:timer_class_info_app))
  end

  def timer_class_info_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer1 = TkTimer.new(500, 1, proc { })
    timer2 = TkTimer.new(500, 1, proc { })

    timer1.start
    timer2.start

    # Class method info() returns all pending timers
    all_info = TkTimer.info
    errors << "TkTimer.info should return array" unless all_info.is_a?(Array)
    errors << "should have at least 2 timers" unless all_info.size >= 2

    # Info for specific timer
    info = TkTimer.info(timer1)
    errors << "info for specific timer should be array" unless info.is_a?(Array)
    errors << "info[0] should be timer1" unless info[0] == timer1

    timer1.cancel
    timer2.cancel

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # delete_procs - remove procs from loop
  # ===========================================

  def test_timer_delete_procs
    assert_tk_app("Timer delete_procs", method(:timer_delete_procs_app))
  end

  def timer_delete_procs_app
    require 'tk'
    require 'tk/timer'

    errors = []

    results = []
    proc1 = proc { results << "first" }
    proc2 = proc { results << "second" }
    proc3 = proc { results << "third" }

    timer = TkTimer.new(30, 1, proc1, proc2, proc3)

    # Delete proc2
    timer.delete_procs(proc2)

    timer.start

    # Wait for callbacks
    start_time = Time.now
    while results.size < 2 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # Should have first and third, not second
    errors << "expected ['first', 'third'], got #{results.inspect}" unless results == ["first", "third"]

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_delete_procs_cancels_if_empty
    assert_tk_app("Timer delete_procs cancels if empty", method(:timer_delete_procs_empty_app))
  end

  def timer_delete_procs_empty_app
    require 'tk'
    require 'tk/timer'

    errors = []

    my_proc = proc { }
    timer = TkTimer.new(500, 1, my_proc)
    timer.start

    errors << "should be running" unless timer.running?

    # Delete the only proc - should auto-cancel
    timer.delete_procs(my_proc)

    errors << "should cancel when all procs deleted" if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # wait methods - block until timer completes
  # ===========================================

  def test_timer_wait
    assert_tk_app("Timer wait", method(:timer_wait_app))
  end

  def timer_wait_app
    require 'tk'
    require 'tk/timer'

    errors = []

    result = nil
    timer = TkTimer.new(30, 1, proc { result = "done" })
    timer.start

    # wait should block until timer completes and return the return_value
    ret = timer.wait
    errors << "wait should return callback result" unless ret == "done"
    errors << "timer should not be running after wait" if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_timer_wait_not_running
    assert_tk_app("Timer wait when not running", method(:timer_wait_not_running_app))
  end

  def timer_wait_not_running_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkTimer.new(30, 1, proc { "completed" })
    timer.start

    # Let it complete
    start_time = Time.now
    while timer.running? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    # wait on already-completed timer should return immediately
    ret = timer.wait
    errors << "wait should return last return_value" unless ret == "completed"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # TkRTTimer - real-time compensated timer
  # ===========================================

  def test_tkrttimer_exists
    assert_tk_app("TkRTTimer exists", method(:tkrttimer_exists_app))
  end

  def tkrttimer_exists_app
    require 'tk'
    require 'tk/timer'

    errors = []

    errors << "TkRTTimer should be defined" unless defined?(TkRTTimer)
    errors << "TkRTTimer should be subclass of TkTimer" unless TkRTTimer < TkTimer

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkrttimer_basic
    assert_tk_app("TkRTTimer basic usage", method(:tkrttimer_basic_app))
  end

  def tkrttimer_basic_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_times = []
    timer = TkRTTimer.new(50, 3, proc { call_times << Time.now })
    timer.start

    # Wait for completion
    start_time = Time.now
    while timer.running? && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "should have 3 calls, got #{call_times.size}" unless call_times.size == 3

    # TkRTTimer compensates for drift - intervals should be closer to target
    # than regular TkTimer (which accumulates delay)
    if call_times.size >= 2
      interval = call_times[1] - call_times[0]
      # Should be reasonably close to 50ms (0.05s)
      errors << "interval should be ~50ms, got #{(interval * 1000).round}ms" if interval > 0.2
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkrttimer_cancel
    assert_tk_app("TkRTTimer cancel", method(:tkrttimer_cancel_app))
  end

  def tkrttimer_cancel_app
    require 'tk'
    require 'tk/timer'

    errors = []

    timer = TkRTTimer.new(500, 5, proc { })
    timer.start

    errors << "should be running" unless timer.running?

    timer.cancel

    errors << "should not be running after cancel" if timer.running?

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkrttimer_continue
    assert_tk_app("TkRTTimer continue", method(:tkrttimer_continue_app))
  end

  def tkrttimer_continue_app
    require 'tk'
    require 'tk/timer'

    errors = []

    call_count = 0
    timer = TkRTTimer.new(30, 3, proc { call_count += 1 })
    timer.start

    # Wait for first callback
    start_time = Time.now
    while call_count < 1 && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    timer.cancel
    count_at_cancel = call_count

    # Continue
    timer.continue

    # Wait for more
    start_time = Time.now
    while call_count <= count_at_cancel && (Time.now - start_time) < 2
      Tk.do_one_event(TclTkLib::DONT_WAIT | TclTkLib::TIMER_EVENTS)
      sleep 0.01
    end

    errors << "should have more calls after continue" unless call_count > count_at_cancel

    timer.cancel if timer.running?

    raise errors.join("\n") unless errors.empty?
  end
end
