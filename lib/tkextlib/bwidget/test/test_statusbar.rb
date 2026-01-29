# frozen_string_literal: true

# Test for Tk::BWidget::StatusBar widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/StatusBar.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetStatusBar < Minitest::Test
  include TkTestHelper

  def test_statusbar_comprehensive
    assert_tk_app("BWidget StatusBar test", method(:statusbar_app))
  end

  def statusbar_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/statusbar'

    errors = []

    # --- Basic StatusBar ---
    statusbar = Tk::BWidget::StatusBar.new(root)
    statusbar.pack(fill: 'x', side: 'bottom')

    # --- get_frame ---
    frame = statusbar.get_frame
    errors << "get_frame failed" if frame.nil?

    # --- add widgets ---
    label1 = TkLabel.new(frame, text: "Status: Ready")
    statusbar.add(label1, weight: 1)

    label2 = TkLabel.new(frame, text: "Line: 1")
    statusbar.add(label2)

    # --- items ---
    # Note: StatusBar auto-inserts separator frames between items
    # So items returns [widget1, separator, widget2, ...]
    items = statusbar.items
    errors << "items should return 3 (2 labels + 1 separator), got #{items.size}" unless items.size == 3
    errors << "items should include label1" unless items.include?(label1)
    errors << "items should include label2" unless items.include?(label2)

    # --- remove (without destroy) ---
    statusbar.remove(label2)
    items = statusbar.items
    errors << "remove failed, expected 1 item, got #{items.size}" unless items.size == 1

    # --- add it back for delete test ---
    label3 = TkLabel.new(frame, text: "Col: 1")
    statusbar.add(label3)

    # --- delete (remove with destroy) ---
    statusbar.delete(label3)
    items = statusbar.items
    errors << "delete failed, expected 1 item, got #{items.size}" unless items.size == 1

    raise "BWidget StatusBar test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
