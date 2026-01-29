# frozen_string_literal: true

# Tests for TkConsole - Tk's built-in console window
#
# What is the Tk Console?
# =======================
# The console is a GUI replacement for stdin/stdout/stderr on platforms
# that don't have a real terminal (Windows GUI apps, macOS .app bundles).
# It creates a text widget where you can type Tcl commands and see output.
#
# When running from a terminal (like we usually do), the console is
# redundant - we already have stdin/stdout. But GUI-only apps need it.
#
# The console is:
# - A separate Tcl interpreter with its own Tk window
# - Connected to the main interpreter's stdout/stderr
# - Controlled via TkConsole.show / TkConsole.hide / TkConsole.title
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/console.html
# See: https://github.com/tcltk/tk/blob/main/library/console.tcl

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestConsole < Minitest::Test
  include TkTestHelper

  def test_console_create
    assert_tk_app("Console create", method(:console_create_app))
  end

  def console_create_app
    require 'tk'
    require 'tk/console'

    errors = []

    # Create the console - this initializes the console interpreter
    # and window (starts hidden because tcl_interactive=0)
    result = TkConsole.create
    errors << "create should return true" unless result == true

    # Console commands should now be available
    # hide - withdraw the console window
    TkConsole.hide

    # show - deiconify the console window
    TkConsole.show

    # title - get/set the console window title
    TkConsole.title("Ruby/Tk Console Test")

    # hide it again before we exit
    TkConsole.hide

    raise errors.join("\n") unless errors.empty?
  end

  def test_console_not_available_message
    # On X11 (Linux), console may not be available
    # This test documents the expected behavior
    skip "Console availability varies by platform"
  end
end
