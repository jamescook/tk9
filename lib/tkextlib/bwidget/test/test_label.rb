# frozen_string_literal: true

# Test for Tk::BWidget::Label widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/Label.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetLabel < Minitest::Test
  include TkTestHelper

  def test_label_comprehensive
    assert_tk_app("BWidget Label test", method(:label_app))
  end

  def label_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic label ---
    label = Tk::BWidget::Label.new(root, text: "Test Label")
    label.pack

    errors << "text failed" unless label.cget(:text) == "Test Label"

    # --- helptext (BWidget-specific string option) ---
    label.configure(helptext: "This is label help")
    errors << "helptext failed" unless label.cget(:helptext) == "This is label help"

    # --- dragenabled/dropenabled (BWidget-specific boolean options) ---
    label.configure(dragenabled: true)
    errors << "dragenabled failed" unless label.cget(:dragenabled) == true

    label.configure(dropenabled: true)
    errors << "dropenabled failed" unless label.cget(:dropenabled) == true

    # --- anchor ---
    label.configure(anchor: "w")
    errors << "anchor failed" unless label.cget(:anchor) == "w"

    # --- foreground/background ---
    label.configure(foreground: "blue", background: "white")
    errors << "foreground failed" if label.cget(:foreground).to_s.empty?
    errors << "background failed" if label.cget(:background).to_s.empty?

    # --- helpvar (TkVariable) ---
    helpvar = TkVariable.new("label help variable")
    label.configure(helpvar: helpvar)
    hv = label.cget(:helpvar)
    errors << "helpvar cget failed" if hv.nil?

    raise "BWidget Label test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
