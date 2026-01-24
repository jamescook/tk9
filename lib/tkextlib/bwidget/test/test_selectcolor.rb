# frozen_string_literal: true

# Test for Tk::BWidget::SelectColor widget options.
# Note: dialog() and menu() methods block for user input.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/SelectColor.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetSelectColor < Minitest::Test
  include TkTestHelper

  def test_selectcolor_comprehensive
    assert_tk_app("BWidget SelectColor test", method(:selectcolor_app))
  end

  def selectcolor_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/selectcolor'

    errors = []

    # --- Create SelectColor base instance ---
    sc = Tk::BWidget::SelectColor.new(root, color: '#ff0000')
    errors << "not a SelectColor" unless sc.is_a?(Tk::BWidget::SelectColor)

    # --- Test class method set_color ---
    # Sets color at index in the palette
    Tk::BWidget::SelectColor.set_color(0, '#00ff00')

    # --- Test Dialog subclass (don't call create - blocks) ---
    dlg = Tk::BWidget::SelectColor::Dialog.new(root, color: '#0000ff')
    errors << "Dialog not a SelectColor subclass" unless dlg.is_a?(Tk::BWidget::SelectColor)

    # --- Test Menubutton subclass ---
    # This creates an actual widget that can be packed
    # Note: Menubutton is created via SelectColor command with type='menubutton'
    # The create_self method handles this specially

    raise "BWidget SelectColor test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
