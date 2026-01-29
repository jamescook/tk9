# frozen_string_literal: true

# Test for Tk::BWidget::MainFrame widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/MainFrame.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetMainFrame < Minitest::Test
  include TkTestHelper

  def test_mainframe_comprehensive
    assert_tk_app("BWidget MainFrame test", method(:mainframe_app))
  end

  def mainframe_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic MainFrame ---
    mainframe = Tk::BWidget::MainFrame.new(root)
    mainframe.pack(fill: 'both', expand: true)

    # --- get_frame ---
    frame = mainframe.get_frame
    errors << "get_frame failed" if frame.nil?

    # --- add_toolbar ---
    toolbar = mainframe.add_toolbar
    errors << "add_toolbar failed" if toolbar.nil?

    # --- get_toolbar ---
    tb = mainframe.get_toolbar(0)
    errors << "get_toolbar failed" if tb.nil?

    # --- add_indicator ---
    indicator = mainframe.add_indicator(text: "Ready")
    errors << "add_indicator failed" if indicator.nil?

    # --- progressvar (TkVariable) ---
    progressvar = TkVariable.new(50)
    mainframe.configure(progressvar: progressvar)
    pv = mainframe.cget(:progressvar)
    errors << "progressvar cget failed" if pv.nil?

    # --- menu option (tests __val2ruby_optkeys -> from_tcl migration) ---
    # Note: menu option returns nested list structure when cget is called
    menu_val = mainframe.cget(:menu)
    # Menu should return something (empty list or actual menu structure)
    errors << "menu cget failed" if menu_val.nil?

    # --- show_statusbar ---
    mainframe.show_statusbar('status')

    raise "BWidget MainFrame test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
