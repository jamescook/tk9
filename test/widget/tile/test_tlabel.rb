# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TLabel widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_label.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTLabelWidget < Minitest::Test
  include TkTestHelper

  def test_tlabel_comprehensive
    assert_tk_app("TLabel widget comprehensive test", method(:tlabel_app))
  end

  def tlabel_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic ttk label ---
    lbl = Tk::Tile::TLabel.new(frame, text: "Hello World")
    lbl.pack(pady: 10)

    errors << "text failed" unless lbl.cget(:text) == "Hello World"

    # --- Configure text ---
    lbl.configure(text: "Updated Label")
    errors << "configure text failed" unless lbl.cget(:text) == "Updated Label"

    # --- Width (in characters) ---
    lbl.configure(width: 30)
    errors << "width failed" unless lbl.cget(:width).to_i == 30

    # --- Anchor ---
    lbl.configure(anchor: "w")
    errors << "anchor failed" unless lbl.cget(:anchor).to_s == "w"

    # --- Justify ---
    lbl.configure(justify: "center")
    errors << "justify failed" unless lbl.cget(:justify) == "center"

    # --- Compound (text + image layout) ---
    lbl.configure(compound: "left")
    errors << "compound failed" unless lbl.cget(:compound) == "left"

    # --- Underline ---
    lbl.configure(underline: 0)
    errors << "underline failed" unless lbl.cget(:underline) == 0

    # --- Wraplength ---
    lbl.configure(wraplength: 200)
    errors << "wraplength failed" unless lbl.cget(:wraplength).to_i == 200

    # --- Relief (ttk::label specific) ---
    lbl.configure(relief: "sunken")
    errors << "relief failed" unless lbl.cget(:relief).to_s == "sunken"

    # --- Style (ttk-specific) ---
    original_style = lbl.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Padding (ttk-specific) ---
    lbl.configure(padding: "5 10")
    # Padding returns can vary, just verify it's configurable
    padding = lbl.cget(:padding)
    errors << "padding cget failed" if padding.nil?

    # --- Multiple labels with different configurations ---
    title_lbl = Tk::Tile::TLabel.new(frame, text: "Title", anchor: "center")
    title_lbl.pack(fill: "x")

    info_lbl = Tk::Tile::TLabel.new(frame, text: "Information text", justify: "left")
    info_lbl.pack(fill: "x")

    errors << "title anchor failed" unless title_lbl.cget(:anchor).to_s == "center"
    errors << "info justify failed" unless info_lbl.cget(:justify) == "left"

    raise "TLabel test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
