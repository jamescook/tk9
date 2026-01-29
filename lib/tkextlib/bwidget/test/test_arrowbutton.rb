# frozen_string_literal: true

# Test for Tk::BWidget::ArrowButton widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetArrowButton < Minitest::Test
  include TkTestHelper

  def test_arrowbutton_comprehensive
    assert_tk_app("BWidget ArrowButton test", method(:arrowbutton_app))
  end

  def arrowbutton_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic arrow button ---
    arrow = Tk::BWidget::ArrowButton.new(root, dir: "top")
    arrow.pack

    errors << "dir failed" unless arrow.cget(:dir) == "top"

    # --- Change direction ---
    arrow.configure(dir: "bottom")
    errors << "dir bottom failed" unless arrow.cget(:dir) == "bottom"

    arrow.configure(dir: "left")
    errors << "dir left failed" unless arrow.cget(:dir) == "left"

    arrow.configure(dir: "right")
    errors << "dir right failed" unless arrow.cget(:dir) == "right"

    # --- state ---
    arrow.configure(state: "disabled")
    errors << "state disabled failed" unless arrow.cget(:state) == "disabled"

    arrow.configure(state: "normal")
    errors << "state normal failed" unless arrow.cget(:state) == "normal"

    # --- width/height ---
    arrow.configure(width: 30, height: 30)
    errors << "width failed" unless arrow.cget(:width).to_i == 30
    errors << "height failed" unless arrow.cget(:height).to_i == 30

    # --- relief ---
    arrow.configure(relief: "raised")
    errors << "relief failed" unless arrow.cget(:relief) == "raised"

    # --- command callback ---
    arrow.configure(command: proc { })
    cmd = arrow.cget(:command)
    errors << "command cget failed" if cmd.nil?

    raise "BWidget ArrowButton test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
