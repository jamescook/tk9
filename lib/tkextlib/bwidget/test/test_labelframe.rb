# frozen_string_literal: true

# Test for Tk::BWidget::LabelFrame widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetLabelFrame < Minitest::Test
  include TkTestHelper

  def test_labelframe_comprehensive
    assert_tk_app("BWidget LabelFrame test", method(:labelframe_app))
  end

  def labelframe_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic label frame ---
    lf = Tk::BWidget::LabelFrame.new(root, text: "Options")
    lf.pack(fill: "both", expand: true, padx: 10, pady: 10)

    errors << "text failed" unless lf.cget(:text) == "Options"

    # --- Get inner frame ---
    inner = lf.get_frame
    errors << "get_frame failed" if inner.nil?

    # --- Add content inside ---
    TkLabel.new(inner, text: "Inside").pack

    # --- relief ---
    lf.configure(relief: "groove")
    errors << "relief failed" unless lf.cget(:relief) == "groove"

    # --- borderwidth ---
    lf.configure(borderwidth: 2)
    errors << "borderwidth failed" unless lf.cget(:borderwidth).to_i == 2

    # --- helptext ---
    lf.configure(helptext: "Frame help text")
    errors << "helptext failed" unless lf.cget(:helptext) == "Frame help text"

    raise "BWidget LabelFrame test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
