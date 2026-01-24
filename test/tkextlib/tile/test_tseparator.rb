# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TSeparator widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_separator.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTSeparatorWidget < Minitest::Test
  include TkTestHelper

  def test_tseparator_comprehensive
    assert_tk_app("TSeparator widget comprehensive test", method(:tseparator_app))
  end

  def tseparator_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Horizontal separator (default) ---
    sep_h = Tk::Tile::TSeparator.new(frame, orient: "horizontal")
    sep_h.pack(fill: "x", pady: 10)

    errors << "horizontal orient failed" unless sep_h.cget(:orient) == "horizontal"

    # --- Vertical separator ---
    sep_v = Tk::Tile::TSeparator.new(frame, orient: "vertical")
    sep_v.pack(fill: "y", padx: 10, side: "left")

    errors << "vertical orient failed" unless sep_v.cget(:orient) == "vertical"

    # --- Change orientation ---
    sep_h.configure(orient: "vertical")
    errors << "orient change failed" unless sep_h.cget(:orient) == "vertical"

    sep_h.configure(orient: "horizontal")
    errors << "orient change back failed" unless sep_h.cget(:orient) == "horizontal"

    # --- Style ---
    original_style = sep_h.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Multiple separators in a layout ---
    content_frame = Tk::Tile::TFrame.new(root, padding: 10)
    content_frame.pack(fill: "both", expand: true)

    Tk::Tile::TLabel.new(content_frame, text: "Section 1").pack(anchor: "w")
    Tk::Tile::TSeparator.new(content_frame, orient: "horizontal").pack(fill: "x", pady: 5)
    Tk::Tile::TLabel.new(content_frame, text: "Section 2").pack(anchor: "w")
    Tk::Tile::TSeparator.new(content_frame, orient: "horizontal").pack(fill: "x", pady: 5)
    Tk::Tile::TLabel.new(content_frame, text: "Section 3").pack(anchor: "w")

    raise "TSeparator test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
