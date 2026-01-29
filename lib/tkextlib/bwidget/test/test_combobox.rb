# frozen_string_literal: true

# Test for Tk::BWidget::ComboBox widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/ComboBox.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetComboBox < Minitest::Test
  include TkTestHelper

  def test_combobox_comprehensive
    assert_tk_app("BWidget ComboBox test", method(:combobox_app))
  end

  def combobox_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- ComboBox with values ---
    combo = Tk::BWidget::ComboBox.new(root,
      values: ['Apple', 'Banana', 'Cherry', 'Date'],
      width: 20
    )
    combo.pack

    # --- values (inherited from SpinBox) ---
    vals = combo.cget(:values)
    errors << "values cget failed" unless vals.is_a?(Array) || vals.to_s.include?("Apple")

    # --- autocomplete (BWidget ComboBox-specific boolean option) ---
    combo.configure(autocomplete: true)
    errors << "autocomplete true failed" unless combo.cget(:autocomplete) == true

    combo.configure(autocomplete: false)
    errors << "autocomplete false failed" unless combo.cget(:autocomplete) == false

    # --- autopost (BWidget ComboBox-specific boolean option) ---
    combo.configure(autopost: true)
    errors << "autopost true failed" unless combo.cget(:autopost) == true

    # --- editable (inherited from SpinBox) ---
    combo.configure(editable: true)
    errors << "editable failed" unless combo.cget(:editable) == true

    # --- helptext (inherited from SpinBox) ---
    combo.configure(helptext: "Select a fruit")
    errors << "helptext failed" unless combo.cget(:helptext) == "Select a fruit"

    # --- clear_value method ---
    combo.clear_value
    # Should not raise error

    raise "BWidget ComboBox test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
