# frozen_string_literal: true

# Test for Tk::BWidget::DragSite module.
# DragSite provides drag-and-drop source functionality.
# Note: Actual DnD operations require user interaction.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/DragSite.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetDragSite < Minitest::Test
  include TkTestHelper

  def test_dragsite_comprehensive
    assert_tk_app("BWidget DragSite test", method(:dragsite_app))
  end

  def dragsite_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/dragsite'

    errors = []

    # --- Create a widget to register as drag source ---
    label = TkLabel.new(root, text: "Drag me")
    label.pack

    # --- Register as drag source ---
    # This sets up the widget to be draggable
    Tk::BWidget::DragSite.register(
      label,
      dragevent: 1,
      draginitcmd: proc { ["TEXT", "COPY", "drag data"] }
    )

    # --- Module should exist ---
    errors << "DragSite module not defined" unless defined?(Tk::BWidget::DragSite)

    raise "BWidget DragSite test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
