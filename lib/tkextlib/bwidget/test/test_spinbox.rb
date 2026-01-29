# frozen_string_literal: true

# Test for Tk::BWidget::SpinBox widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/SpinBox.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetSpinBox < Minitest::Test
  include TkTestHelper

  def test_spinbox_comprehensive
    assert_tk_app("BWidget SpinBox test", method(:spinbox_app))
  end

  def spinbox_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- SpinBox with values list ---
    spinbox = Tk::BWidget::SpinBox.new(root,
      values: ['One', 'Two', 'Three', 'Four', 'Five'],
      width: 15
    )
    spinbox.pack

    # --- values (BWidget-specific list option) ---
    vals = spinbox.cget(:values)
    errors << "values cget failed" unless vals.is_a?(Array) || vals.to_s.include?("One")

    # --- helptext (BWidget-specific string option) ---
    spinbox.configure(helptext: "Select a value")
    errors << "helptext failed" unless spinbox.cget(:helptext) == "Select a value"

    # --- editable (BWidget-specific boolean option) ---
    spinbox.configure(editable: true)
    errors << "editable true failed" unless spinbox.cget(:editable) == true

    spinbox.configure(editable: false)
    errors << "editable false failed" unless spinbox.cget(:editable) == false

    # --- dragenabled/dropenabled ---
    spinbox.configure(dragenabled: true)
    errors << "dragenabled failed" unless spinbox.cget(:dragenabled) == true

    # --- entryfg/entrybg (BWidget-specific string options) ---
    spinbox.configure(entryfg: "black", entrybg: "white")
    errors << "entryfg failed" if spinbox.cget(:entryfg).to_s.empty?
    errors << "entrybg failed" if spinbox.cget(:entrybg).to_s.empty?

    # --- set/get value by index ---
    spinbox.set_value_by_index(2)  # Select "Three"
    idx = spinbox.get_index_of_value
    errors << "set/get value index failed" unless idx == 2

    # --- helpvar (TkVariable) ---
    helpvar = TkVariable.new("spinbox help variable")
    spinbox.configure(helpvar: helpvar)
    hv = spinbox.cget(:helpvar)
    errors << "helpvar cget failed" if hv.nil?

    raise "BWidget SpinBox test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
