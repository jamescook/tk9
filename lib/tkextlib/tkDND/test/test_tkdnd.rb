# frozen_string_literal: true

# Test for Tk::TkDND extension integration.
#
# This test verifies that the tkdnd Tcl package can be loaded and
# the Ruby bindings work correctly. It does NOT test actual drag-and-drop
# (which requires user interaction).
#
# Run with: rake tkdnd:test
# See: https://github.com/petasis/tkdnd
#
# Known tkdnd bugs (in tkdnd_compat.tcl, not Ruby):
#   1. bindsource query returns <<DropTargetTypes>> instead of <<DragSourceTypes>>
#      so dnd_bindsource_info returns wrong/empty results
#   2. cleartarget/clearsource are no-ops (empty procs), bindings persist
# These don't affect actual drag/drop functionality, just introspection/cleanup.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestTkDND < Minitest::Test
  include TkTestHelper

  def test_tkdnd_integration
    assert_tk_app("TkDND integration test", method(:tkdnd_app))
  end

  def tkdnd_app
    require 'tk'
    require 'tkextlib/tkDND'

    errors = []

    # Verify package loaded (DND access triggers autoload of tkdnd.rb)
    version = Tk::TkDND::DND.version
    errors << "version returned empty" if version.nil? || version.empty?

    # Create widgets for testing
    target = TkLabel.new(root, text: "Drop zone", width: 30, height: 5)
    target.pack

    source = TkLabel.new(root, text: "Drag me", width: 20, height: 3)
    source.pack

    # Platform-appropriate type
    drop_type = case Tk.windowingsystem
                when 'aqua' then 'NSPasteboardTypeString'
                else 'text/plain'
                end

    # --- Test drop target registration ---
    target.dnd_bindtarget(drop_type, '<Drop>') do |event|
      # callback registered
    end

    # Verify via <<DropTargetTypes>> virtual event (the actual storage)
    target_types = Tk.ip_eval("bind #{target.path} <<DropTargetTypes>>")
    errors << "drop target not registered" if target_types.empty?
    errors << "wrong target type: #{target_types}" unless target_types.include?(drop_type)

    # --- Test drag source registration ---
    source.dnd_bindsource(drop_type) { "Hello from Ruby-Tk!" }

    # Verify via <<DragSourceTypes>> virtual event (the actual storage)
    # Note: dnd_bindsource_info is broken in tkdnd_compat.tcl (queries wrong event)
    source_types = Tk.ip_eval("bind #{source.path} <<DragSourceTypes>>")
    errors << "drag source not registered" if source_types.empty?
    errors << "wrong source type: #{source_types}" unless source_types.include?(drop_type)

    # Verify <<DragInitCmd>> is set (this is what triggers the drag)
    init_cmd = Tk.ip_eval("bind #{source.path} <<DragInitCmd>>")
    errors << "<<DragInitCmd>> not set" if init_cmd.empty?

    # --- Verify methods don't error (even if they don't work correctly) ---
    # These are no-ops in tkdnd_compat.tcl but shouldn't raise
    target.dnd_cleartarget
    source.dnd_clearsource

    raise "TkDND test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
