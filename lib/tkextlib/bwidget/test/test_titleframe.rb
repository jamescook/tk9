# frozen_string_literal: true

# Test for Tk::BWidget::TitleFrame widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetTitleFrame < Minitest::Test
  include TkTestHelper

  def test_titleframe_comprehensive
    assert_tk_app("BWidget TitleFrame test", method(:titleframe_app))
  end

  def titleframe_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic title frame ---
    tf = Tk::BWidget::TitleFrame.new(root, text: "Frame Title")
    tf.pack(fill: "both", expand: true, padx: 10, pady: 10)

    errors << "text failed" unless tf.cget(:text) == "Frame Title"

    # --- Change text ---
    tf.configure(text: "New Title")
    errors << "text change failed" unless tf.cget(:text) == "New Title"

    # --- Get frame for adding children ---
    inner = tf.get_frame
    errors << "get_frame failed" if inner.nil?

    # --- Add a widget inside ---
    label = TkLabel.new(inner, text: "Inside frame")
    label.pack

    # --- relief ---
    tf.configure(relief: "groove")
    errors << "relief failed" unless tf.cget(:relief) == "groove"

    # --- borderwidth ---
    tf.configure(borderwidth: 2)
    errors << "borderwidth failed" unless tf.cget(:borderwidth).to_i == 2

    raise "BWidget TitleFrame test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
