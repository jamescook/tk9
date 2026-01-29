# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TMenubutton widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_menubutton.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTMenubuttonWidget < Minitest::Test
  include TkTestHelper

  def test_tmenubutton_comprehensive
    assert_tk_app("TMenubutton widget comprehensive test", method(:tmenubutton_app))
  end

  def tmenubutton_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # Create a menu for the menubutton
    menu = TkMenu.new(root, tearoff: false)
    menu.add(:command, label: "Option 1")
    menu.add(:command, label: "Option 2")
    menu.add(:command, label: "Option 3")

    # --- Basic menubutton with menu ---
    mb = Tk::Tile::TMenubutton.new(frame, text: "Select Option", menu: menu)
    mb.pack(pady: 10)

    errors << "text failed" unless mb.cget(:text) == "Select Option"

    # --- Direction option ---
    mb.configure(direction: "below")
    errors << "direction below failed" unless mb.cget(:direction) == "below"

    mb.configure(direction: "above")
    errors << "direction above failed" unless mb.cget(:direction) == "above"

    mb.configure(direction: "left")
    errors << "direction left failed" unless mb.cget(:direction) == "left"

    mb.configure(direction: "right")
    errors << "direction right failed" unless mb.cget(:direction) == "right"

    # --- Width ---
    mb.configure(width: 20)
    errors << "width failed" unless mb.cget(:width).to_i == 20

    # --- State ---
    mb.configure(state: "disabled")
    errors << "disabled state failed" unless mb.cget(:state) == "disabled"

    mb.configure(state: "normal")
    errors << "normal state failed" unless mb.cget(:state) == "normal"

    # --- Compound ---
    mb.configure(compound: "left")
    errors << "compound failed" unless mb.cget(:compound) == "left"

    # --- Underline ---
    mb.configure(underline: 0)
    errors << "underline failed" unless mb.cget(:underline) == 0

    # --- Style ---
    original_style = mb.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Second menubutton ---
    menu2 = TkMenu.new(root, tearoff: false)
    menu2.add(:command, label: "A")
    menu2.add(:command, label: "B")

    mb2 = Tk::Tile::TMenubutton.new(frame, text: "File", menu: menu2, direction: "below")
    mb2.pack(pady: 5)
    errors << "second menubutton text failed" unless mb2.cget(:text) == "File"

    raise "TMenubutton test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
