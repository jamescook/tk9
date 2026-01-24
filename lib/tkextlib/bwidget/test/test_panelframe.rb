# frozen_string_literal: true

# Test for Tk::BWidget::PanelFrame widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/PanelFrame.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetPanelFrame < Minitest::Test
  include TkTestHelper

  def test_panelframe_comprehensive
    assert_tk_app("BWidget PanelFrame test", method(:panelframe_app))
  end

  def panelframe_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/panelframe'

    errors = []

    # --- Basic PanelFrame ---
    pf = Tk::BWidget::PanelFrame.new(root, text: "Panel Title")
    pf.pack(fill: 'both', expand: true)

    # --- get_frame (the content area) ---
    frame = pf.get_frame
    errors << "get_frame failed" if frame.nil?

    # --- Add content to the main frame area ---
    content = TkLabel.new(frame, text: "Content goes here")
    content.pack(fill: 'both', expand: true)

    # --- Add widgets to title bar area ---
    # PanelFrame::add places widgets in the label/title area
    btn1 = TkButton.new(root, text: "X")
    pf.add(btn1, side: 'right')

    btn2 = TkButton.new(root, text: "?")
    pf.add(btn2, side: 'right')

    # --- items ---
    items = pf.items
    errors << "items should return 2 widgets, got #{items.size}" unless items.size == 2

    # --- remove (without destroy) ---
    pf.remove(btn2)
    items = pf.items
    errors << "remove failed, expected 1 item, got #{items.size}" unless items.size == 1

    # --- delete (remove with destroy) ---
    pf.delete(btn1)
    items = pf.items
    errors << "delete failed, expected 0 items, got #{items.size}" unless items.size == 0

    raise "BWidget PanelFrame test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
