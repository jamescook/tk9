# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TFrame widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_frame.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTFrameWidget < Minitest::Test
  include TkTestHelper

  def test_tframe_comprehensive
    assert_tk_app("TFrame widget comprehensive test", method(:tframe_app))
  end

  def tframe_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # --- Basic ttk frame ---
    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # Padding (ttk-specific)
    padding = frame.cget(:padding)
    errors << "padding cget failed" if padding.nil?

    # --- Width and height (inherited from Frame) ---
    frame.configure(width: 300)
    errors << "width failed" unless frame.cget(:width).to_i == 300

    frame.configure(height: 200)
    errors << "height failed" unless frame.cget(:height).to_i == 200

    # --- Border and relief ---
    frame.configure(borderwidth: 2)
    errors << "borderwidth failed" unless frame.cget(:borderwidth).to_i == 2

    frame.configure(relief: "raised")
    errors << "relief failed" unless frame.cget(:relief).to_s == "raised"

    # --- Style (ttk-specific) ---
    original_style = frame.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Nested frames ---
    inner_frame = Tk::Tile::TFrame.new(frame, padding: "5 10 5 10")
    inner_frame.pack(fill: "both", expand: true, padx: 10, pady: 10)

    inner_padding = inner_frame.cget(:padding)
    errors << "inner frame padding failed" if inner_padding.nil?

    # --- Add content to inner frame ---
    label = Tk::Tile::TLabel.new(inner_frame, text: "Content inside TFrame")
    label.pack(pady: 10)

    errors << "label in frame failed" unless label.cget(:text) == "Content inside TFrame"

    raise "TFrame test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
