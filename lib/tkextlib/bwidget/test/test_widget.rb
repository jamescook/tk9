# frozen_string_literal: true

# Test for Tk::BWidget::Widget module.
# This is a utility module for BWidget widget infrastructure.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/Widget.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetWidget < Minitest::Test
  include TkTestHelper

  def test_widget_comprehensive
    assert_tk_app("BWidget Widget test", method(:widget_app))
  end

  def widget_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/widget'

    errors = []

    # --- Module should exist ---
    errors << "Widget module not defined" unless defined?(Tk::BWidget::Widget)

    # --- Verify expected methods are defined ---
    # Widget is infrastructure for megawidget construction
    expected_methods = %i[add_map bwinclude create declare define destroy
                          focus_next focus_ok focus_prev get_option
                          set_option sub_cget sync_options tkinclude]
    expected_methods.each do |m|
      unless Tk::BWidget::Widget.respond_to?(m)
        errors << "Widget should respond to #{m}"
      end
    end

    # --- Test with an actual BWidget (not plain Tk widget) ---
    require 'tkextlib/bwidget/button'
    btn = Tk::BWidget::Button.new(root, text: "BWidget Button")
    btn.pack
    Tk.update

    # destroy works on BWidget widgets
    Tk::BWidget::Widget.destroy(btn)

    raise "BWidget Widget test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
