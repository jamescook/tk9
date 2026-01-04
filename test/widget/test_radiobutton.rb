# frozen_string_literal: true

# Comprehensive test for Tk::RadioButton and Tk::CheckButton widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/radiobutton.html
# See: https://www.tcl-lang.org/man/tcl/TkCmd/checkbutton.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestRadioButtonWidget < Minitest::Test
  include TkTestHelper

  def test_radiobutton_comprehensive
    assert_tk_app("RadioButton widget comprehensive test", method(:radiobutton_app))
  end

  def radiobutton_app
    require 'tk'
    require 'tk/radiobutton'
    require 'tk/checkbutton'
    require 'tk/frame'
    require 'tk/labelframe'

    root = TkRoot.new { withdraw }
    errors = []

    frame = TkFrame.new(root, padx: 20, pady: 20)
    frame.pack(fill: "both", expand: true)

    # --- RadioButton group ---
    radio_frame = TkLabelFrame.new(frame, text: "Select Size")
    radio_frame.pack(fill: "x", pady: 5)

    size_var = TkVariable.new("medium")

    rb_small = TkRadioButton.new(radio_frame,
      text: "Small",
      variable: size_var,
      value: "small"
    )
    rb_small.pack(anchor: "w")

    rb_medium = TkRadioButton.new(radio_frame,
      text: "Medium",
      variable: size_var,
      value: "medium"
    )
    rb_medium.pack(anchor: "w")

    rb_large = TkRadioButton.new(radio_frame,
      text: "Large",
      variable: size_var,
      value: "large"
    )
    rb_large.pack(anchor: "w")

    # --- RadioButton value ---
    errors << "radiobutton value failed" unless rb_small.cget(:value) == "small"
    errors << "radiobutton variable failed" unless size_var.value == "medium"

    # --- Indicator on/off (DSL-declared boolean) ---
    rb_small.configure(indicatoron: true)
    errors << "indicatoron true failed" unless rb_small.cget(:indicatoron)
    errors << "indicatoron true not boolean" unless rb_small.cget(:indicatoron).is_a?(TrueClass)

    rb_small.configure(indicatoron: false)
    errors << "indicatoron false failed" if rb_small.cget(:indicatoron)
    errors << "indicatoron false not boolean" unless rb_small.cget(:indicatoron).is_a?(FalseClass)

    rb_small.configure(indicatoron: true)

    # --- Select color ---
    rb_small.configure(selectcolor: "red")
    errors << "selectcolor failed" if rb_small.cget(:selectcolor).to_s.empty?

    # --- Select/deselect methods ---
    rb_large.select
    errors << "select method failed" unless size_var.value == "large"

    rb_small.select
    errors << "select small failed" unless size_var.value == "small"

    # --- State (inherited) ---
    rb_small.configure(state: "disabled")
    errors << "disabled state failed" unless rb_small.cget(:state) == "disabled"

    rb_small.configure(state: "normal")
    errors << "normal state failed" unless rb_small.cget(:state) == "normal"

    # --- CheckButton ---
    check_frame = TkLabelFrame.new(frame, text: "Options")
    check_frame.pack(fill: "x", pady: 5)

    opt1_var = TkVariable.new("0")
    opt2_var = TkVariable.new("0")

    cb1 = TkCheckButton.new(check_frame,
      text: "Enable notifications",
      variable: opt1_var,
      onvalue: "yes",
      offvalue: "no"
    )
    cb1.pack(anchor: "w")

    cb2 = TkCheckButton.new(check_frame,
      text: "Auto-save",
      variable: opt2_var
    )
    cb2.pack(anchor: "w")

    # --- CheckButton onvalue/offvalue (DSL-declared) ---
    errors << "onvalue failed" unless cb1.cget(:onvalue) == "yes"
    errors << "offvalue failed" unless cb1.cget(:offvalue) == "no"

    # --- CheckButton select/deselect ---
    cb1.select
    errors << "checkbutton select failed" unless opt1_var.value == "yes"

    cb1.deselect
    errors << "checkbutton deselect failed" unless opt1_var.value == "no"

    # --- CheckButton toggle ---
    cb1.toggle
    errors << "checkbutton toggle failed" unless opt1_var.value == "yes"

    # --- CheckButton indicatoron (inherited from RadioButton) ---
    cb1.configure(indicatoron: false)
    errors << "checkbutton indicatoron false failed" if cb1.cget(:indicatoron)
    errors << "checkbutton indicatoron not boolean" unless cb1.cget(:indicatoron).is_a?(FalseClass)

    cb1.configure(indicatoron: true)

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "RadioButton/CheckButton test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
