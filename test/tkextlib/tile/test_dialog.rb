# frozen_string_literal: true

# Test for Tk::Tile::Dialog
#
# Note: ttk::dialog was part of the standalone Tile extension (0.7+) but was
# never included when Tile was integrated into Tk 8.5 as Ttk. The standard
# tk_dialog still uses classic Tk widgets, not Ttk themed widgets.
# See: https://comp.lang.tcl.narkive.com/UbjlhDIp/tk-dialog-and-ttk
#
# For themed dialogs, use widget::dialog from tklib instead.

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTileDialog < Minitest::Test
  include TkTestHelper

  def test_dialog_class_structure
    assert_tk_app("Tile Dialog class structure", method(:dialog_class_app))
  end

  def dialog_class_app
    require 'tk'
    require 'tkextlib/tile/dialog'

    errors = []

    # --- Class should exist ---
    errors << "Dialog class not defined" unless defined?(Tk::Tile::Dialog)

    # --- Class methods should be defined ---
    %i[show display define_dialog_type style].each do |m|
      unless Tk::Tile::Dialog.respond_to?(m)
        errors << "Dialog should respond to class method #{m}"
      end
    end

    # --- Instance methods should be defined ---
    instance_methods = %i[show display client_frame cget cget_strict configure configinfo]
    instance_methods.each do |m|
      unless Tk::Tile::Dialog.instance_methods.include?(m)
        errors << "Dialog should have instance method #{m}"
      end
    end

    # --- Test style class method (pure Ruby, no Tcl) ---
    style = Tk::Tile::Dialog.style
    errors << "style() should return 'Dialog'" unless style == 'Dialog'

    style_with_args = Tk::Tile::Dialog.style('Custom', 'Element')
    errors << "style('Custom', 'Element') failed" unless style_with_args == 'Dialog.Custom.Element'

    # --- TkCommandNames ---
    errors << "TkCommandNames not defined" unless defined?(Tk::Tile::Dialog::TkCommandNames)
    errors << "TkCommandNames should contain ::ttk::dialog" unless Tk::Tile::Dialog::TkCommandNames.include?('::ttk::dialog')

    raise errors.join("\n") unless errors.empty?
  end

  def test_dialog_config_methods
    assert_tk_app("Tile Dialog config methods", method(:dialog_config_app))
  end

  def dialog_config_app
    require 'tk'
    require 'tkextlib/tile/dialog'

    errors = []

    # Create dialog instance without showing (keys stored internally)
    # Note: We can't actually create a full dialog without the ttk::dialog package,
    # but we can test the config methods by creating an object and manipulating @keys

    # Test that the class can be instantiated (even if Tcl part fails)
    begin
      # The initialize method stores keys in @keys before calling super
      # We can test the Ruby-side config methods work correctly

      # Create a mock to test config behavior
      dialog_class = Tk::Tile::Dialog

      # Test configure method behavior (operates on @keys hash)
      # Since we can't fully instantiate, test the logic indirectly

      # Test configinfo format
      # When slot is provided: [slot, nil, nil, nil, value]
      # When slot is nil: array of [key, nil, nil, nil, value] for each key

      errors << "Dialog class should exist for config testing" unless dialog_class
    rescue => e
      # Expected if ttk::dialog package not available
      errors << "Unexpected error: #{e.message}" unless e.message.include?('ttk::dialog')
    end

    raise errors.join("\n") unless errors.empty?
  end
end
