# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TRadioButton and TCheckButton widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_radiobutton.html
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_checkbutton.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTRadiobuttonWidget < Minitest::Test
  include TkTestHelper

  def test_tradiobutton_comprehensive
    assert_tk_app("TRadioButton/TCheckButton widget comprehensive test", method(:tradiobutton_app))
  end

  def tradiobutton_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Radio buttons with shared variable ---
    choice = TkVariable.new("option1")

    rb1 = Tk::Tile::TRadioButton.new(frame,
      text: "Option 1",
      variable: choice,
      value: "option1"
    )
    rb1.pack(anchor: "w")

    rb2 = Tk::Tile::TRadioButton.new(frame,
      text: "Option 2",
      variable: choice,
      value: "option2"
    )
    rb2.pack(anchor: "w")

    rb3 = Tk::Tile::TRadioButton.new(frame,
      text: "Option 3",
      variable: choice,
      value: "option3"
    )
    rb3.pack(anchor: "w")

    errors << "rb1 text failed" unless rb1.cget(:text) == "Option 1"
    errors << "rb1 value failed" unless rb1.cget(:value) == "option1"

    # Initial selection
    errors << "initial selection failed" unless choice.value == "option1"

    # Invoke second radio button
    rb2.invoke
    errors << "invoke selection failed" unless choice.value == "option2"

    # --- State ---
    rb3.configure(state: "disabled")
    errors << "disabled state failed" unless rb3.cget(:state) == "disabled"

    rb3.configure(state: "normal")
    errors << "normal state failed" unless rb3.cget(:state) == "normal"

    # --- Width ---
    rb1.configure(width: 15)
    errors << "width failed" unless rb1.cget(:width).to_i == 15

    # --- Compound ---
    rb1.configure(compound: "left")
    errors << "compound failed" unless rb1.cget(:compound) == "left"

    # --- Underline ---
    rb1.configure(underline: 0)
    errors << "underline failed" unless rb1.cget(:underline) == 0

    # --- Style ---
    original_style = rb1.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # ========================================
    # TCheckButton tests
    # ========================================

    check_frame = Tk::Tile::TFrame.new(root, padding: 20)
    check_frame.pack(fill: "both", expand: true)

    # --- Check button with variable ---
    enabled = TkVariable.new(false)

    cb1 = Tk::Tile::TCheckButton.new(check_frame,
      text: "Enable feature",
      variable: enabled
    )
    cb1.pack(anchor: "w")

    errors << "cb1 text failed" unless cb1.cget(:text) == "Enable feature"

    # Initial state (unchecked)
    errors << "initial check state failed" unless enabled.bool == false

    # Toggle via invoke
    cb1.invoke
    errors << "invoke check failed" unless enabled.bool == true

    cb1.invoke
    errors << "invoke uncheck failed" unless enabled.bool == false

    # --- Custom on/off values ---
    status = TkVariable.new("off")

    cb2 = Tk::Tile::TCheckButton.new(check_frame,
      text: "Status",
      variable: status,
      onvalue: "on",
      offvalue: "off"
    )
    cb2.pack(anchor: "w")

    errors << "offvalue failed" unless cb2.cget(:offvalue) == "off"
    errors << "onvalue failed" unless cb2.cget(:onvalue) == "on"

    cb2.invoke
    errors << "custom onvalue invoke failed" unless status.value == "on"

    # --- State ---
    cb1.configure(state: "disabled")
    errors << "cb disabled state failed" unless cb1.cget(:state) == "disabled"

    cb1.configure(state: "normal")

    # --- Width ---
    cb1.configure(width: 20)
    errors << "cb width failed" unless cb1.cget(:width).to_i == 20

    # --- Style ---
    cb_style = cb1.cget(:style)
    errors << "cb style cget failed" if cb_style.nil?

    raise "TRadioButton/TCheckButton test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
