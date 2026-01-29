#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Test multiple independent Tcl interpreters using TclTkIp directly
#
# Uses polling approach with DONT_WAIT + sleep for multi-interpreter support.
# Note: On macOS, all GUI must be on the main thread, so we use a combined
# event loop that polls all interpreters.
#
# Run: ruby -Ilib sample/multi_interp_test.rb
#

$stdout.sync = true

require 'tcltklib'
require 'set'

puts "=== Multi-Interpreter Test ==="
puts

# Create 3 independent interpreters
interps = []
closed_interps = Set.new

3.times do |i|
  interp = TclTkIp.new
  interps << interp

  puts "Interpreter #{i + 1} created"

  interp.tcl_eval("wm title . {Interpreter #{i + 1}}")
  interp.tcl_eval("wm geometry . 300x150+#{50 + i * 320}+100")

  # Each has its own click counter (isolated state)
  click_count = 0

  click_cb = interp.register_callback(proc {
    click_count += 1
    interp.tcl_invoke(".lbl", "configure", "-text", "Interp #{i + 1}: clicked #{click_count}x")
    puts "Interpreter #{i + 1} clicked! Count: #{click_count}"
  })

  interp.tcl_invoke("label", ".lbl", "-text", "Interp #{i + 1}: click the button")
  interp.tcl_invoke("pack", ".lbl", "-pady", "20")

  interp.tcl_invoke("button", ".btn", "-text", "Click Me (Interp #{i + 1})",
                    "-command", "ruby_callback #{click_cb}")
  interp.tcl_invoke("pack", ".btn", "-pady", "10")

  close_cb = interp.register_callback(proc {
    puts "Closing interpreter #{i + 1}..."
    closed_interps << interp
    interp.tcl_eval("destroy .")
  })
  interp.tcl_invoke("button", ".close", "-text", "Close This Window",
                    "-command", "ruby_callback #{close_cb}")
  interp.tcl_invoke("pack", ".close", "-pady", "5")
end

puts
puts "Created #{interps.size} interpreters."
puts "Each has its own state - clicking one doesn't affect others."
puts "Close all windows to exit."
puts

# Smoke test support - save FD for signaling at the very end
ready_fd = ENV.delete('TK_READY_FD')

if ready_fd
  # Process events briefly to ensure windows are up
  3.times do
    interps.each { |ip| ip.do_one_event(TclTkLib::ALL_EVENTS | TclTkLib::DONT_WAIT) }
    sleep 0.01
  end

  # Invoke close buttons directly (synchronously triggers "Closing interpreter N...")
  interps.each do |interp|
    interp.tcl_eval(".close invoke")
  end
end

# Helper to check if interpreter is still active
def interp_active?(interp, closed_set)
  !interp.deleted? && !closed_set.include?(interp)
end

# Combined event loop - process events from all interpreters
# Uses DONT_WAIT so we can poll multiple interpreters without blocking
running = true
while running
  active_interps = interps.select { |ip| interp_active?(ip, closed_interps) }

  if active_interps.empty?
    running = false
  else
    active_interps.each do |interp|
      # Non-blocking event processing
      interp.do_one_event(TclTkLib::ALL_EVENTS | TclTkLib::DONT_WAIT)
    end

    # Small sleep to avoid busy-waiting (necessary for multi-interpreter polling)
    sleep 0.001
  end
end

puts
puts "=== Done! ==="
$stdout.flush

# Signal ready at the very end - process exits immediately after
if ready_fd
  IO.for_fd(ready_fd.to_i).tap { |io| io.write("1"); io.close } rescue nil
end
