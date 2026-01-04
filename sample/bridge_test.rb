#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Test script for the new TclTkBridge with Ruby callbacks
# Run: ruby -I ext/tk/tcltkbridge -I lib sample/bridge_test.rb
#

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../ext/tk/tcltkbridge', __dir__)

require 'tk/bridge'
require 'tk/tcl_list_parser'

puts "=== TclTkBridge Callback Test ==="
puts

# Create a bridge instance (each has its own interpreter + callback registry)
puts "Creating bridge..."
bridge = Tk::Bridge.new
puts "Tcl version: #{bridge.tcl_version}"
puts "Tk version: #{bridge.tk_version}"
puts

# Set up the window
bridge.eval("wm title . {TclTkBridge Callback Test}")
bridge.eval("wm geometry . 400x200")

# Track click count
click_count = 0

# Register a callback for the button
button_cb = bridge.register_callback do |*args|
  click_count += 1
  puts "Button clicked! Count: #{click_count} (args: #{args.inspect})"
  bridge.invoke(".lbl", "configure", "-text", "Clicked #{click_count} times!")
end

# Register callback to show widget tree (demonstrates list parsing)
tree_cb = bridge.register_callback do
  # Get all children of root window - returns Tcl list
  children_str = bridge.eval("winfo children .")

  # Parse using our pure Ruby parser (faster than Tcl eval with YJIT!)
  children = Tk::TclListParser.parse(children_str)

  puts "Widget tree (parsed with TclListParser):"
  children.each do |child|
    # Get widget class
    widget_class = bridge.eval("winfo class #{child}")
    puts "  #{child} (#{widget_class})"
  end
  puts

  bridge.invoke(".lbl", "configure", "-text", "Found #{children.size} widgets")
end

# Register callback to test emoji round-trip
emoji_cb = bridge.register_callback do
  emoji_text = "🎉 Party! 日本語 👋🏽"
  bridge.invoke(".lbl", "configure", "-text", emoji_text)
  # Verify round-trip
  result = bridge.invoke(".lbl", "cget", "-text")
  puts "Emoji test: #{emoji_text == result ? '✓' : '✗'} (#{result.inspect})"
end

# Register callback to test vwait/tkwait behavior
vwait_cb = bridge.register_callback do
  puts "Opening modal dialog..."
  bridge.invoke(".lbl", "configure", "-text", "Dialog open - try clicking main window!")

  # Create a toplevel dialog
  bridge.invoke("toplevel", ".dialog")
  bridge.invoke("wm", "title", ".dialog", "Modal Test")
  bridge.invoke("wm", "geometry", ".dialog", "250x120")

  # Add a close button
  bridge.eval('button .dialog.close -text "Close Dialog" -command {destroy .dialog}')
  bridge.invoke("pack", ".dialog.close", "-pady", "10")

  bridge.invoke("label", ".dialog.info", "-text", "Main window stays responsive!\nTry clicking 'Click me!' button")
  bridge.invoke("pack", ".dialog.info", "-pady", "5")

  # Use our Ruby-based tkwait - UI stays responsive AND Ruby callbacks fire
  puts "Waiting for dialog to close..."
  puts "(Main window is still responsive - try clicking buttons!)"
  start = Time.now
  bridge.tkwait_window(".dialog")
  elapsed = ((Time.now - start) * 1000).to_i

  puts "Dialog closed after #{elapsed}ms"
  bridge.invoke(".lbl", "configure", "-text", "Dialog was open #{elapsed}ms")
end

# Register an exit callback
exit_cb = bridge.register_callback do
  puts "Exit button clicked, stopping..."
  bridge.stop
end

# Create widgets
bridge.invoke("button", ".btn", "-text", "Click me!",
              "-command", bridge.tcl_callback_command(button_cb))
bridge.invoke("pack", ".btn", "-pady", "10")

bridge.invoke("button", ".tree", "-text", "Show Widget Tree",
              "-command", bridge.tcl_callback_command(tree_cb))
bridge.invoke("pack", ".tree", "-pady", "5")

bridge.invoke("button", ".emoji", "-text", "Test Emoji 🎉",
              "-command", bridge.tcl_callback_command(emoji_cb))
bridge.invoke("pack", ".emoji", "-pady", "5")

bridge.invoke("button", ".vwait", "-text", "Test Modal (tkwait)",
              "-command", bridge.tcl_callback_command(vwait_cb))
bridge.invoke("pack", ".vwait", "-pady", "5")

bridge.invoke("button", ".exit", "-text", "Exit",
              "-command", bridge.tcl_callback_command(exit_cb))
bridge.invoke("pack", ".exit", "-pady", "5")

bridge.invoke("label", ".lbl", "-text", "Click the button!")
bridge.invoke("pack", ".lbl", "-pady", "10")

bridge.invoke("label", ".info",
              "-text", "Pure Ruby: callbacks + list parsing (YJIT-optimized)",
              "-font", "TkSmallCaptionFont")
bridge.invoke("pack", ".info", "-side", "bottom", "-pady", "5")

puts "Window created."
puts "  'Click me!' - test callback dispatch"
puts "  'Show Widget Tree' - test TclListParser"
puts "  'Test Emoji' - test UTF-8/emoji round-trip"
puts "  'Test Modal' - test tkwait (blocks but UI stays responsive)"
puts "  'Exit' - quit"
puts

# --- Activity monitor windows ---
# These update continuously to show the event loop isn't blocked

# Window 1: Random hex from /dev/urandom
bridge.invoke("toplevel", ".activity1")
bridge.invoke("wm", "title", ".activity1", "Activity Monitor 1")
bridge.invoke("wm", "geometry", ".activity1", "250x80+420+50")
bridge.invoke("label", ".activity1.title", "-text", "Random hex (updates every 100ms)")
bridge.invoke("pack", ".activity1.title")
bridge.invoke("label", ".activity1.data", "-text", "...", "-font", "TkFixedFont")
bridge.invoke("pack", ".activity1.data", "-pady", "10")

activity1_cb = bridge.register_callback do
  hex = File.read("/dev/urandom", 8).unpack1("H*")
  bridge.invoke(".activity1.data", "configure", "-text", hex) rescue nil
end
# Schedule repeating update via Tcl's after
bridge.eval("proc update_activity1 {} { #{bridge.tcl_callback_command(activity1_cb)}; after 100 update_activity1 }")
bridge.eval("after 100 update_activity1")

# Windows 2-7: Tick counters (6 windows updating every 25ms)
# Shows tick count and actual ms since last tick (to detect lag)
tick_data = Array.new(6) { { count: 0, last: Time.now } }

6.times do |i|
  win_num = i + 2
  win = ".activity#{win_num}"
  y_offset = 180 + (i * 90)

  bridge.invoke("toplevel", win)
  bridge.invoke("wm", "title", win, "Activity Monitor #{win_num}")
  bridge.invoke("wm", "geometry", win, "250x70+420+#{y_offset}")
  bridge.invoke("label", "#{win}.title", "-text", "Tick ##{win_num} (25ms target)")
  bridge.invoke("pack", "#{win}.title")
  bridge.invoke("label", "#{win}.data", "-text", "0", "-font", "TkFixedFont")
  bridge.invoke("pack", "#{win}.data", "-pady", "5")

  cb = bridge.register_callback do
    now = Time.now
    delta_ms = ((now - tick_data[i][:last]) * 1000).round
    tick_data[i][:last] = now
    tick_data[i][:count] += 1
    # Warn if > 10% over budget (25ms * 1.1 = 27.5ms)
    if delta_ms > 27
      puts "⚠️  Activity #{win_num} lag: #{delta_ms}ms (budget: 25ms)"
    end
    # Show tick count and actual interval (should be ~25ms)
    bridge.invoke("#{win}.data", "configure", "-text",
      "Tick: #{tick_data[i][:count]}  (#{delta_ms}ms)") rescue nil
  end
  bridge.eval("proc update_activity#{win_num} {} { #{bridge.tcl_callback_command(cb)}; after 25 update_activity#{win_num} }")
  bridge.eval("after 25 update_activity#{win_num}")
end

puts "Activity monitors running - they should keep updating even during modal dialogs!"
puts

# Run event loop
bridge.mainloop

puts
puts "=== Done! Button was clicked #{click_count} times ==="
