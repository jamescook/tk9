# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TScale widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_scale.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTScaleWidget < Minitest::Test
  include TkTestHelper

  def test_tscale_comprehensive
    assert_tk_app("TScale widget comprehensive test", method(:tscale_app))
  end

  def tscale_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Horizontal scale ---
    Tk::Tile::TLabel.new(frame, text: "Horizontal (0-100):").pack(anchor: "w")
    hscale = Tk::Tile::TScale.new(frame,
      orient: "horizontal",
      from: 0,
      to: 100,
      length: 200
    )
    hscale.pack(fill: "x", pady: 5)

    errors << "orient horizontal failed" unless hscale.cget(:orient) == "horizontal"
    errors << "from failed" unless hscale.cget(:from).to_f == 0.0
    errors << "to failed" unless hscale.cget(:to).to_f == 100.0
    errors << "length failed" unless hscale.cget(:length).to_i == 200

    # --- Set and get value ---
    hscale.set(50)
    val = hscale.get
    errors << "set/get failed" unless val.to_f >= 49.0 && val.to_f <= 51.0

    # --- Vertical scale ---
    Tk::Tile::TLabel.new(frame, text: "Vertical (0-1):").pack(anchor: "w")
    vscale = Tk::Tile::TScale.new(frame,
      orient: "vertical",
      from: 0.0,
      to: 1.0,
      length: 150
    )
    vscale.pack(pady: 5)

    errors << "orient vertical failed" unless vscale.cget(:orient) == "vertical"

    vscale.set(0.5)
    val = vscale.get
    errors << "vertical set/get failed" unless val.to_f >= 0.4 && val.to_f <= 0.6

    # --- Variable binding ---
    var = TkVariable.new(25)
    bound_scale = Tk::Tile::TScale.new(frame,
      orient: "horizontal",
      from: 0,
      to: 100,
      variable: var
    )
    bound_scale.pack(fill: "x", pady: 5)

    # Verify initial value from variable
    errors << "variable initial failed" unless bound_scale.get.to_f == 25.0

    # Change variable, verify scale updates
    var.value = 75
    errors << "variable update failed" unless bound_scale.get.to_f == 75.0

    # --- Command callback ---
    callback_value = nil
    callback_scale = Tk::Tile::TScale.new(frame,
      orient: "horizontal",
      from: 0,
      to: 100,
      command: proc { |val| callback_value = val.to_f }
    )
    callback_scale.pack(fill: "x", pady: 5)

    callback_scale.set(30)
    # Note: command is called when value changes via widget, set may or may not trigger it
    # Just verify command is configurable
    cmd = callback_scale.cget(:command)
    errors << "command cget failed" if cmd.nil?

    # --- Style (ttk-specific) ---
    original_style = hscale.cget(:style)
    errors << "style cget failed" if original_style.nil?

    raise "TScale test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
