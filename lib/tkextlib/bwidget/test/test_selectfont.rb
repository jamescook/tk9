# frozen_string_literal: true

# Test for Tk::BWidget::SelectFont widget options.
# Note: create() on Dialog blocks for user input.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/SelectFont.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetSelectFont < Minitest::Test
  include TkTestHelper

  def test_selectfont_comprehensive
    assert_tk_app("BWidget SelectFont test", method(:selectfont_app))
  end

  def selectfont_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/selectfont'

    errors = []

    # --- Test Dialog subclass (don't call create - blocks) ---
    dlg = Tk::BWidget::SelectFont::Dialog.new(root)
    errors << "Dialog not a SelectFont subclass" unless dlg.is_a?(Tk::BWidget::SelectFont)

    # --- Test Toolbar subclass (creates actual widget) ---
    toolbar = Tk::BWidget::SelectFont::Toolbar.new(root)
    errors << "Toolbar not created" if toolbar.nil?
    toolbar.pack

    # --- Test load_font class method ---
    Tk::BWidget::SelectFont.load_font

    raise "BWidget SelectFont test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
