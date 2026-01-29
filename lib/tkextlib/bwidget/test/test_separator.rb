# frozen_string_literal: true

# Test for Tk::BWidget::Separator widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetSeparator < Minitest::Test
  include TkTestHelper

  def test_separator_comprehensive
    assert_tk_app("BWidget Separator test", method(:separator_app))
  end

  def separator_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Horizontal separator ---
    sep_h = Tk::BWidget::Separator.new(root, orient: "horizontal")
    sep_h.pack(fill: "x", pady: 10)

    errors << "orient horizontal failed" unless sep_h.cget(:orient) == "horizontal"

    # --- Vertical separator ---
    sep_v = Tk::BWidget::Separator.new(root, orient: "vertical")
    sep_v.pack(fill: "y", padx: 10)

    errors << "orient vertical failed" unless sep_v.cget(:orient) == "vertical"

    # --- background color ---
    sep_h.configure(background: "gray")
    errors << "background failed" if sep_h.cget(:background).to_s.empty?

    raise "BWidget Separator test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
