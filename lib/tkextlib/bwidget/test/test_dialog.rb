# frozen_string_literal: true

# Test for Tk::BWidget::Dialog widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/Dialog.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetDialog < Minitest::Test
  include TkTestHelper

  def test_dialog_comprehensive
    assert_tk_app("BWidget Dialog test", method(:dialog_app))
  end

  def dialog_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Create dialog (not shown) ---
    dlg = Tk::BWidget::Dialog.new(root, title: "Test Dialog")

    errors << "title failed" unless dlg.cget(:title) == "Test Dialog"

    # --- Configure options ---
    dlg.configure(modal: "none")
    errors << "modal failed" unless dlg.cget(:modal) == "none"

    # --- Configure side (button placement) ---
    dlg.configure(side: "bottom")
    errors << "side failed" unless dlg.cget(:side) == "bottom"

    # --- Add multiple buttons ---
    btn0 = dlg.add(text: "OK")
    errors << "add returned nil" if btn0.nil?
    dlg.add(text: "Cancel")
    dlg.add(text: "Help")

    # --- Get frame for content ---
    frame = dlg.get_frame
    errors << "get_frame failed" if frame.nil?

    # --- Get buttonbox ---
    bbox = dlg.get_buttonbox
    errors << "get_buttonbox failed" if bbox.nil?

    # --- Add content to frame ---
    TkLabel.new(frame, text: "Dialog content").pack

    # --- index ---
    idx = dlg.index(0)
    errors << "index(0) failed" if idx.nil?

    # --- set_focus (doesn't show dialog, just sets internal focus widget) ---
    result = dlg.set_focus(1)
    errors << "set_focus failed" unless result == dlg

    # --- invoke (triggers button command) ---
    # Note: invoke returns self, actual command effect depends on button config
    result = dlg.invoke(0)
    errors << "invoke failed" unless result == dlg

    # --- configinfo ---
    info = dlg.configinfo
    errors << "configinfo failed" if info.nil? || info.empty?

    # Test configinfo with specific option
    title_info = dlg.configinfo(:title)
    errors << "configinfo(:title) failed" if title_info.nil?

    # --- relative/parent option (Dialog-specific alias) ---
    # Dialog uses 'relative' as alias for 'parent' option
    dlg2 = Tk::BWidget::Dialog.new(root, title: "Dialog 2", relative: root)
    rel_info = dlg2.configinfo(:relative)
    errors << "relative option failed" if rel_info.nil?
    dlg2.withdraw

    # --- cget_strict and cget_tkstring ---
    title_strict = dlg.cget_strict(:title)
    errors << "cget_strict failed" unless title_strict == "Test Dialog"

    title_str = dlg.cget_tkstring(:title)
    errors << "cget_tkstring failed" unless title_str == "Test Dialog"

    # --- withdraw (don't show during test) ---
    dlg.withdraw

    # --- enddialog (ends modal dialog loop with return value) ---
    # When modal is "none", this won't block but we can still call it
    dlg.enddialog(42)

    raise "BWidget Dialog test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
