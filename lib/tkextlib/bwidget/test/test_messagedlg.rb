# frozen_string_literal: true

# Test for Tk::BWidget::MessageDlg widget options.
# Note: create() blocks waiting for user input, so we only test configuration.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/MessageDlg.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetMessageDlg < Minitest::Test
  include TkTestHelper

  def test_messagedlg_comprehensive
    assert_tk_app("BWidget MessageDlg test", method(:messagedlg_app))
  end

  def messagedlg_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/messagedlg'

    errors = []

    # --- Create MessageDlg with options (don't call create - it blocks) ---
    dlg = Tk::BWidget::MessageDlg.new(
      root,
      title: "Test Dialog",
      message: "This is a test message",
      type: 'ok',
      icon: 'info'
    )

    # --- Verify it's a MessageDlg instance ---
    errors << "not a MessageDlg" unless dlg.is_a?(Tk::BWidget::MessageDlg)

    # --- Test cget ---
    title = dlg.cget(:title)
    errors << "cget title failed: #{title.inspect}" unless title == "Test Dialog"

    msg = dlg.cget(:message)
    errors << "cget message failed: #{msg.inspect}" unless msg == "This is a test message"

    # --- Test configure ---
    dlg.configure(message: "Updated message")
    msg = dlg.cget(:message)
    errors << "configure message failed: #{msg.inspect}" unless msg == "Updated message"

    # --- Test relative option (alias for parent) ---
    dlg2 = Tk::BWidget::MessageDlg.new(relative: root, message: "Test")
    errors << "relative option failed" unless dlg2.is_a?(Tk::BWidget::MessageDlg)

    raise "BWidget MessageDlg test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
