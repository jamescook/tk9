# frozen_string_literal: true

# Test for Tk::BWidget::ScrollView widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetScrollView < Minitest::Test
  include TkTestHelper

  def test_scrollview_comprehensive
    assert_tk_app("BWidget ScrollView test", method(:scrollview_app))
  end

  def scrollview_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Create canvas ---
    canvas = TkCanvas.new(root, width: 200, height: 200)
    canvas.pack

    # --- Create scrollview (associate with canvas) ---
    sv = Tk::BWidget::ScrollView.new(canvas)
    sv.pack

    # --- Configure ---
    sv.configure(width: 50, height: 50)
    errors << "width failed" unless sv.cget(:width).to_i == 50
    errors << "height failed" unless sv.cget(:height).to_i == 50

    raise "BWidget ScrollView test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
