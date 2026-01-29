# frozen_string_literal: true

# Test for Tk::BWidget::ScrolledWindow widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetScrolledWindow < Minitest::Test
  include TkTestHelper

  def test_scrolledwindow_comprehensive
    assert_tk_app("BWidget ScrolledWindow test", method(:scrolledwindow_app))
  end

  def scrolledwindow_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic scrolled window ---
    sw = Tk::BWidget::ScrolledWindow.new(root)
    sw.pack(fill: "both", expand: true, padx: 10, pady: 10)

    # --- Add scrollable content ---
    text = TkText.new(sw)
    sw.set_widget(text)

    # --- scrollbar mode ---
    sw.configure(scrollbar: "both")
    errors << "scrollbar both failed" unless sw.cget(:scrollbar) == "both"

    sw.configure(scrollbar: "vertical")
    errors << "scrollbar vertical failed" unless sw.cget(:scrollbar) == "vertical"

    sw.configure(scrollbar: "horizontal")
    errors << "scrollbar horizontal failed" unless sw.cget(:scrollbar) == "horizontal"

    # --- auto scrollbar ---
    sw.configure(auto: "both")
    errors << "auto failed" unless sw.cget(:auto) == "both"

    raise "BWidget ScrolledWindow test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
