# frozen_string_literal: true

# Test for Tk::BWidget::Button widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/Button.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetButton < Minitest::Test
  include TkTestHelper

  def test_button_comprehensive
    assert_tk_app("BWidget Button test", method(:button_app))
  end

  def button_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic button ---
    button = Tk::BWidget::Button.new(root, text: "Test Button")
    button.pack

    errors << "text failed" unless button.cget(:text) == "Test Button"

    # --- helptext (BWidget-specific string option) ---
    button.configure(helptext: "This is help text")
    errors << "helptext failed" unless button.cget(:helptext) == "This is help text"

    # --- command callback ---
    clicked = false
    button.configure(command: proc { clicked = true })
    cmd = button.cget(:command)
    errors << "command cget failed" if cmd.nil?

    # --- state ---
    button.configure(state: "disabled")
    errors << "state disabled failed" unless button.cget(:state) == "disabled"

    button.configure(state: "normal")
    errors << "state normal failed" unless button.cget(:state) == "normal"

    # --- width/height ---
    button.configure(width: 20)
    errors << "width failed" unless button.cget(:width).to_i == 20

    # --- relief ---
    button.configure(relief: "raised")
    errors << "relief failed" unless button.cget(:relief) == "raised"

    # --- helpvar (TkVariable) ---
    helpvar = TkVariable.new("help variable content")
    button.configure(helpvar: helpvar)
    hv = button.cget(:helpvar)
    errors << "helpvar cget failed" if hv.nil?

    raise "BWidget Button test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
