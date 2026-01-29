# frozen_string_literal: true

# Test for Tk::BWidget::ProgressBar widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetProgressBar < Minitest::Test
  include TkTestHelper

  def test_progressbar_comprehensive
    assert_tk_app("BWidget ProgressBar test", method(:progressbar_app))
  end

  def progressbar_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic progress bar ---
    pb = Tk::BWidget::ProgressBar.new(root, maximum: 100)
    pb.pack(fill: "x", padx: 10, pady: 10)

    errors << "maximum failed" unless pb.cget(:maximum).to_i == 100

    # --- Set variable for progress ---
    var = TkVariable.new(50)
    pb.configure(variable: var)
    errors << "variable cget failed" if pb.cget(:variable).nil?

    # --- width/height ---
    pb.configure(width: 200, height: 20)
    errors << "width failed" unless pb.cget(:width).to_i == 200
    errors << "height failed" unless pb.cget(:height).to_i == 20

    # --- foreground/background ---
    pb.configure(foreground: "blue", background: "white")
    errors << "foreground failed" if pb.cget(:foreground).to_s.empty?
    errors << "background failed" if pb.cget(:background).to_s.empty?

    # --- orient ---
    pb.configure(orient: "horizontal")
    errors << "orient failed" unless pb.cget(:orient) == "horizontal"

    raise "BWidget ProgressBar test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
