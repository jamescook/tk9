# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TSpinbox widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_spinbox.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTSpinboxWidget < Minitest::Test
  include TkTestHelper

  def test_tspinbox_comprehensive
    assert_tk_app("TSpinbox widget comprehensive test", method(:tspinbox_app))
  end

  def tspinbox_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Numeric spinbox with from/to/increment ---
    Tk::Tile::TLabel.new(frame, text: "Numeric (0-100, step 5):").pack(anchor: "w")
    numeric = Tk::Tile::TSpinbox.new(frame,
      from: 0,
      to: 100,
      increment: 5,
      width: 10
    )
    numeric.pack(pady: 5)

    errors << "from failed" unless numeric.cget(:from).to_f == 0.0
    errors << "to failed" unless numeric.cget(:to).to_f == 100.0
    errors << "increment failed" unless numeric.cget(:increment).to_f == 5.0

    # --- Set and get value ---
    numeric.set(50)
    errors << "set failed" unless numeric.get == "50"

    # --- Wrap option ---
    numeric.configure(wrap: true)
    errors << "wrap true failed" unless numeric.cget(:wrap) == true

    numeric.configure(wrap: false)
    errors << "wrap false failed" unless numeric.cget(:wrap) == false

    # --- Float format ---
    Tk::Tile::TLabel.new(frame, text: "Float (0.0-1.0, step 0.1):").pack(anchor: "w")
    float_spin = Tk::Tile::TSpinbox.new(frame,
      from: 0.0,
      to: 1.0,
      increment: 0.1,
      format: "%0.2f",
      width: 10
    )
    float_spin.pack(pady: 5)

    errors << "float format failed" unless float_spin.cget(:format) == "%0.2f"

    float_spin.set(0.5)
    # Format may adjust the display
    val = float_spin.get.to_f
    errors << "float set failed" unless val >= 0.49 && val <= 0.51

    # --- Values list (discrete values) ---
    Tk::Tile::TLabel.new(frame, text: "Discrete values:").pack(anchor: "w")
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    discrete = Tk::Tile::TSpinbox.new(frame,
      values: days,
      wrap: true,
      width: 15
    )
    discrete.pack(pady: 5)

    # Values cget returns the list
    cget_values = discrete.cget(:values)
    errors << "values cget failed" unless cget_values.is_a?(Array) || cget_values.to_s.include?("Monday")

    discrete.set("Wednesday")
    errors << "discrete set failed" unless discrete.get == "Wednesday"

    # --- Command callback (triggered when spin buttons pressed) ---
    spin_count = 0
    callback_spin = Tk::Tile::TSpinbox.new(frame,
      from: 0,
      to: 10,
      width: 10,
      command: proc { spin_count += 1 }
    )
    callback_spin.pack(pady: 5)

    # Invoke spin programmatically if possible
    # Note: There's no direct invoke method, but we test the command is set
    cmd = callback_spin.cget(:command)
    errors << "command cget failed" if cmd.nil?

    # --- State ---
    numeric.configure(state: "readonly")
    errors << "readonly state failed" unless numeric.cget(:state) == "readonly"

    numeric.configure(state: "disabled")
    errors << "disabled state failed" unless numeric.cget(:state) == "disabled"

    numeric.configure(state: "normal")
    errors << "normal state failed" unless numeric.cget(:state) == "normal"

    # --- Style (ttk-specific) ---
    original_style = numeric.cget(:style)
    errors << "style cget failed" if original_style.nil?

    raise "TSpinbox test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
