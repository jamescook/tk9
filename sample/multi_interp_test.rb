#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Test multiple independent Tcl interpreters
#
# Uses polling approach with DONT_WAIT + sleep for multi-interpreter support.
# Note: On macOS, all GUI must be on the main thread, so we use a combined
# event loop that polls all interpreters.
#
# Run: ruby -I ext/tk/tcltkbridge -I lib sample/multi_interp_test.rb
#

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../ext/tk/tcltkbridge', __dir__)

require 'tk/bridge'

puts "=== Multi-Interpreter Test ==="
puts

# Create 3 independent interpreters
bridges = []

3.times do |i|
  bridge = Tk::Bridge.new
  bridges << bridge

  puts "Interpreter #{i + 1} created"

  bridge.eval("wm title . {Interpreter #{i + 1}}")
  bridge.eval("wm geometry . 300x150+#{50 + i * 320}+100")

  # Each has its own click counter (isolated state)
  click_count = 0

  click_cb = bridge.register_callback do
    click_count += 1
    bridge.invoke(".lbl", "configure", "-text", "Interp #{i + 1}: clicked #{click_count}x")
    puts "Interpreter #{i + 1} clicked! Count: #{click_count}"
  end

  bridge.invoke("label", ".lbl", "-text", "Interp #{i + 1}: click the button")
  bridge.invoke("pack", ".lbl", "-pady", "20")

  bridge.invoke("button", ".btn", "-text", "Click Me (Interp #{i + 1})",
                "-command", bridge.tcl_callback_command(click_cb))
  bridge.invoke("pack", ".btn", "-pady", "10")

  close_cb = bridge.register_callback do
    puts "Closing interpreter #{i + 1}..."
    bridge.eval("destroy .")
  end
  bridge.invoke("button", ".close", "-text", "Close This Window",
                "-command", bridge.tcl_callback_command(close_cb))
  bridge.invoke("pack", ".close", "-pady", "5")
end

puts
puts "Created 3 interpreters."
puts "Each has its own state - clicking one doesn't affect others."
puts "Close all windows to exit."
puts

# Combined event loop - process events from all interpreters
# Uses DONT_WAIT so we can poll multiple interpreters without blocking
running = true
while running
  active_bridges = bridges.select { |b| b.window_exists?(".") }

  if active_bridges.empty?
    running = false
  else
    active_bridges.each do |bridge|
      # Non-blocking event processing
      bridge.interp.do_one_event(TclTkBridge::ALL_EVENTS | TclTkBridge::DONT_WAIT)
      bridge.dispatch_pending_callbacks
    end
    # Small sleep to avoid busy-waiting (necessary for multi-interpreter polling)
    sleep 0.001
  end
end

puts
puts "=== Done! ==="
