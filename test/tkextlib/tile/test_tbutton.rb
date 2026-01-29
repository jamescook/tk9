# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TButton widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_button.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTButtonWidget < Minitest::Test
  include TkTestHelper

  def test_tbutton_comprehensive
    assert_tk_app("TButton widget comprehensive test", method(:tbutton_app))
  end

  def tbutton_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic ttk button ---
    btn = Tk::Tile::TButton.new(frame, text: "Click Me")
    btn.pack(pady: 10)

    errors << "text failed" unless btn.cget(:text) == "Click Me"

    # --- Command callback ---
    clicked = false
    btn.configure(command: proc { clicked = true })
    btn.invoke
    errors << "command/invoke failed" unless clicked

    # --- Width ---
    btn.configure(width: 20)
    errors << "width failed" unless btn.cget(:width).to_i == 20

    # --- State ---
    btn.configure(state: "disabled")
    errors << "disabled state failed" unless btn.cget(:state) == "disabled"

    btn.configure(state: "normal")
    errors << "normal state failed" unless btn.cget(:state) == "normal"

    # --- Default (dialog button prominence) ---
    btn.configure(default: "active")
    errors << "default active failed" unless btn.cget(:default) == "active"

    btn.configure(default: "normal")
    errors << "default normal failed" unless btn.cget(:default) == "normal"

    # --- Compound (text + image layout) ---
    btn.configure(compound: "left")
    errors << "compound failed" unless btn.cget(:compound) == "left"

    # --- Underline ---
    btn.configure(underline: 0)
    errors << "underline failed" unless btn.cget(:underline) == 0

    # --- Style (ttk-specific) ---
    # Just verify it's configurable - actual style must exist
    original_style = btn.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Multiple buttons ---
    ok_btn = Tk::Tile::TButton.new(frame, text: "OK", default: "active")
    ok_btn.pack(side: "left", padx: 5)

    cancel_btn = Tk::Tile::TButton.new(frame, text: "Cancel")
    cancel_btn.pack(side: "left", padx: 5)

    errors << "ok default failed" unless ok_btn.cget(:default) == "active"

    raise "TButton test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
