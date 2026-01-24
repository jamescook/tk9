# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TLabelframe widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_labelframe.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTLabelframeWidget < Minitest::Test
  include TkTestHelper

  def test_tlabelframe_comprehensive
    assert_tk_app("TLabelframe widget comprehensive test", method(:tlabelframe_app))
  end

  def tlabelframe_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic labelframe with text ---
    lf = Tk::Tile::TLabelframe.new(frame, text: "Options")
    lf.pack(fill: "both", expand: true, pady: 10)

    errors << "text failed" unless lf.cget(:text) == "Options"

    # Add content inside labelframe
    Tk::Tile::TCheckButton.new(lf, text: "Enable feature").pack(anchor: "w", padx: 10)
    Tk::Tile::TCheckButton.new(lf, text: "Show warnings").pack(anchor: "w", padx: 10)

    # --- Label anchor ---
    lf.configure(labelanchor: "nw")
    errors << "labelanchor nw failed" unless lf.cget(:labelanchor) == "nw"

    lf.configure(labelanchor: "n")
    errors << "labelanchor n failed" unless lf.cget(:labelanchor) == "n"

    # --- Underline (mnemonic) ---
    lf.configure(underline: 0)
    errors << "underline failed" unless lf.cget(:underline) == 0

    # --- Width and height (inherited from TFrame) ---
    lf.configure(width: 300)
    errors << "width failed" unless lf.cget(:width).to_i == 300

    lf.configure(height: 150)
    errors << "height failed" unless lf.cget(:height).to_i == 150

    # --- Padding (inherited from TFrame) ---
    lf.configure(padding: "10 5")
    padding = lf.cget(:padding)
    errors << "padding cget failed" if padding.nil?

    # --- Multiple labelframes ---
    settings_lf = Tk::Tile::TLabelframe.new(frame, text: "Settings", labelanchor: "nw")
    settings_lf.pack(fill: "x", pady: 5)

    Tk::Tile::TLabel.new(settings_lf, text: "Name:").pack(side: "left", padx: 5)
    Tk::Tile::TEntry.new(settings_lf, width: 20).pack(side: "left", padx: 5)

    errors << "settings text failed" unless settings_lf.cget(:text) == "Settings"

    # --- Style (ttk-specific, inherited from TFrame) ---
    original_style = lf.cget(:style)
    errors << "style cget failed" if original_style.nil?

    raise "TLabelframe test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
