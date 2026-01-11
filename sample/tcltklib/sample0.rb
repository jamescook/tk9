#!/usr/bin/env ruby
# frozen_string_literal: true

# Low-level tcltklib demo - shows direct TclTkIp usage
#
# This demonstrates:
#   - Creating multiple Tcl interpreters
#   - Evaluating Tcl code directly
#   - Calling Ruby from Tcl
#   - Running the global Tk event loop (TclTkLib.mainloop)

$stdout.sync = true

require "tcltklib"

def test
  # Create first interpreter
  ip1 = TclTkIp.new

  # Evaluate Tcl code
  puts "Tcl puts: #{ip1.tcl_eval('puts {abc}').inspect}"

  # Create a button
  ip1.tcl_eval('button .lab -text exit -command "destroy ."')
  ip1.tcl_eval('pack .lab')

  # Call Ruby from Tcl - the 'ruby' command executes Ruby code
  result = ip1.tcl_eval('puts [ruby {print "Ruby says hello\n"; "returned to Tcl"}]')
  puts "Ruby->Tcl result: #{result.inspect}"

  # Create second interpreter with its own window
  ip2 = TclTkIp.new
  ip2.tcl_eval('button .lab -text "test (ip2)" -command "puts test; destroy ."')
  ip2.tcl_eval('pack .lab')

  puts "Two windows created."

  # Smoke test support - auto-click and exit when running under test harness
  if (fd_str = ENV.delete('TK_READY_FD'))
    # Schedule button clicks to auto-close windows
    ip1.tcl_eval('after 50 {.lab invoke}')
    ip2.tcl_eval('after 100 {.lab invoke}')

    # Signal ready immediately so test harness knows we're up
    IO.for_fd(fd_str.to_i).tap { |io| io.write("1"); io.close } rescue nil
  else
    puts "Click buttons to close."
  end

  TclTkLib.mainloop
end

test
puts "exit"
