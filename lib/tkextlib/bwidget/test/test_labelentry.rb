# frozen_string_literal: true

# Test for Tk::BWidget::LabelEntry widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetLabelEntry < Minitest::Test
  include TkTestHelper

  def test_labelentry_comprehensive
    assert_tk_app("BWidget LabelEntry test", method(:labelentry_app))
  end

  def labelentry_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic label entry ---
    le = Tk::BWidget::LabelEntry.new(root, label: "Name:", text: "initial")
    le.pack(fill: "x", padx: 10, pady: 10)

    errors << "label failed" unless le.cget(:label) == "Name:"
    errors << "text failed" unless le.cget(:text) == "initial"

    # --- Change text ---
    le.configure(text: "new value")
    errors << "text change failed" unless le.cget(:text) == "new value"

    # --- width ---
    le.configure(width: 30)
    errors << "width failed" unless le.cget(:width).to_i == 30

    # --- state ---
    le.configure(state: "disabled")
    errors << "state disabled failed" unless le.cget(:state) == "disabled"

    le.configure(state: "normal")
    errors << "state normal failed" unless le.cget(:state) == "normal"

    # --- helptext ---
    le.configure(helptext: "Enter your name")
    errors << "helptext failed" unless le.cget(:helptext) == "Enter your name"

    raise "BWidget LabelEntry test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
