# frozen_string_literal: true

# Test for Tk::BWidget::PanedWindow widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetPanedWindow < Minitest::Test
  include TkTestHelper

  def test_panedwindow_comprehensive
    assert_tk_app("BWidget PanedWindow test", method(:panedwindow_app))
  end

  def panedwindow_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Paned window ---
    pw = Tk::BWidget::PanedWindow.new(root)
    pw.pack(fill: "both", expand: true, padx: 10, pady: 10)

    # --- Add panes ---
    pane1 = pw.add(weight: 1)
    pane2 = pw.add(weight: 1)

    errors << "add pane1 failed" if pane1.nil?
    errors << "add pane2 failed" if pane2.nil?

    # --- Add content to panes ---
    TkLabel.new(pane1, text: "Pane 1").pack
    TkLabel.new(pane2, text: "Pane 2").pack

    # --- Get frame ---
    frame = pw.get_frame(0)
    errors << "get_frame failed" if frame.nil?

    raise "BWidget PanedWindow test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
