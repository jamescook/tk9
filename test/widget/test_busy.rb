# frozen_string_literal: true

# Test for Tk::Busy module.
# tk busy makes a window "busy" (shows busy cursor, blocks interaction).
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/busy.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestBusy < Minitest::Test
  include TkTestHelper

  def test_busy_comprehensive
    assert_tk_app("Busy comprehensive test", method(:busy_app))
  end

  def busy_app
    require 'tk'
    require 'tk/busy'

    errors = []

    # Create a frame to make busy
    frame = TkFrame.new(root, width: 200, height: 100)
    frame.pack

    # --- Hold (make busy) ---
    Tk::Busy.hold(frame)
    errors << "status should be true after hold" unless Tk::Busy.status(frame) == true

    # --- Current (list busy windows) ---
    current = Tk::Busy.current
    # current returns widget objects
    errors << "current should include frame" unless current.any? { |w| w.path == frame.path }

    # --- Configure cursor ---
    Tk::Busy.configure(frame, cursor: 'watch')
    cursor_val = Tk::Busy.cget(frame, :cursor)
    errors << "cursor should be watch, got #{cursor_val}" unless cursor_val.to_s.include?('watch')

    # --- Configinfo ---
    info = Tk::Busy.configinfo(frame)
    errors << "configinfo should return array" unless info.is_a?(Array)

    # --- Configinfo for specific option ---
    cursor_info = Tk::Busy.configinfo(frame, :cursor)
    errors << "cursor configinfo should be array" unless cursor_info.is_a?(Array)

    # --- Forget (release busy) ---
    Tk::Busy.forget(frame)
    errors << "status should be false after forget" unless Tk::Busy.status(frame) == false

    # --- Test mixin methods on window ---
    frame2 = TkFrame.new(root, width: 200, height: 100)
    frame2.pack

    frame2.busy  # mixin method
    errors << "mixin busy_status should be true" unless frame2.busy_status == true

    frame2.busy_configure(cursor: 'watch')

    frame2.busy_forget
    errors << "mixin busy_status should be false after forget" unless frame2.busy_status == false

    # Check errors
    unless errors.empty?
      raise "Busy test failures:\n  " + errors.join("\n  ")
    end
  end
end
