# frozen_string_literal: true

# Test for Tk::BWidget::DynamicHelp module.
# DynamicHelp provides tooltip/balloon help functionality.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/DynamicHelp.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetDynamicHelp < Minitest::Test
  include TkTestHelper

  def test_dynamichelp_comprehensive
    assert_tk_app("BWidget DynamicHelp test", method(:dynamichelp_app))
  end

  def dynamichelp_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/dynamichelp'

    errors = []

    # --- Create a button to attach help to ---
    btn = TkButton.new(root, text: "Hover me")
    btn.pack

    # --- Add dynamic help (tooltip) ---
    Tk::BWidget::DynamicHelp.add(btn, text: "This is help text")

    # --- Delete help ---
    Tk::BWidget::DynamicHelp.delete(btn)

    # --- Add help with variable ---
    help_var = TkVariable.new("Variable help text")
    Tk::BWidget::DynamicHelp.add(btn, variable: help_var)

    # --- Add help to another widget with balloon type ---
    label = TkLabel.new(root, text: "Label with help")
    label.pack
    Tk::BWidget::DynamicHelp.add(label, text: "Label tooltip", type: 'balloon')

    raise "BWidget DynamicHelp test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
