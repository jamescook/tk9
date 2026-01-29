# frozen_string_literal: true

# Test for Tk::BWidget::ScrollableFrame widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetScrollableFrame < Minitest::Test
  include TkTestHelper

  def test_scrollableframe_comprehensive
    assert_tk_app("BWidget ScrollableFrame test", method(:scrollableframe_app))
  end

  def scrollableframe_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Create scrollable frame ---
    sf = Tk::BWidget::ScrollableFrame.new(root)
    sf.pack(fill: "both", expand: true, padx: 10, pady: 10)

    # --- Get inner frame ---
    inner = sf.get_frame
    errors << "get_frame failed" if inner.nil?

    # --- Add content to inner frame ---
    10.times do |i|
      TkLabel.new(inner, text: "Item #{i}").pack
    end

    # --- constrainedwidth ---
    sf.configure(constrainedwidth: true)
    cw = sf.cget(:constrainedwidth)
    errors << "constrainedwidth failed" unless cw == true || cw == "1" || cw == 1

    raise "BWidget ScrollableFrame test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
