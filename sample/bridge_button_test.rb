#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Test Tk::Bridge::Button - should work like TkButton
#
# Run: ruby -Ilib sample/bridge_button_test.rb
#

$stdout.sync = true

require 'tk/bridge'
require 'tk/bridge/button'

puts "=== Bridge Button Test ==="

bridge = Tk::Bridge.new
bridge.eval("wm title . {Bridge Button Test}")

click_count = 0

# DSL style (like TkButton)
btn = Tk::Bridge::Button.new(bridge, text: "Click me") {
  command {
    click_count += 1
    puts "Clicked #{click_count} times!"
  }
  pack pady: 20, padx: 50
}

# Also test hash style for command
quit_btn = Tk::Bridge::Button.new(bridge, text: "Quit", command: -> {
  puts "Quit clicked, destroying..."
  bridge.eval("destroy .")
})
quit_btn.pack(pady: 10)

puts "UI ready. Click buttons to test."

# Smoke test support
if ENV['TK_READY_FD']
  bridge.eval('set ::visible 0')
  bridge.eval('bind . <Visibility> { set ::visible 1 }')
end

# Simple mainloop with callback dispatch
while bridge.window_exists?(".")
  bridge.interp.do_one_event(TclTkLib::ALL_EVENTS | TclTkLib::DONT_WAIT)
  bridge.dispatch_pending_callbacks

  if ENV['TK_READY_FD'] && bridge.eval('set ::visible') == '1'
    ENV.delete('TK_READY_FD')
    btn.invoke
    btn.invoke
    quit_btn.invoke
  end

  sleep 0.001
end

puts "=== Done! ==="
