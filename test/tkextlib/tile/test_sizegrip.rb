# frozen_string_literal: true

# Comprehensive test for Tk::Tile::SizeGrip widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_sizegrip.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestSizeGripWidget < Minitest::Test
  include TkTestHelper

  def test_sizegrip_comprehensive
    assert_tk_app("SizeGrip widget comprehensive test", method(:sizegrip_app))
  end

  def sizegrip_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic sizegrip ---
    # SizeGrip is typically placed in bottom-right corner for window resizing
    grip = Tk::Tile::SizeGrip.new(frame)
    grip.pack(side: "bottom", anchor: "se")

    # SizeGrip has very few options - mainly style
    style = grip.cget(:style)
    errors << "style cget failed" if style.nil?

    # --- Second sizegrip in a different context ---
    status_frame = Tk::Tile::TFrame.new(root)
    status_frame.pack(side: "bottom", fill: "x")

    status_label = Tk::Tile::TLabel.new(status_frame, text: "Ready")
    status_label.pack(side: "left")

    grip2 = Tk::Tile::SizeGrip.new(status_frame)
    grip2.pack(side: "right")

    # Verify both exist
    errors << "second grip failed" if grip2.nil?

    # --- Cursor option (standard option) ---
    grip.configure(cursor: "sizing")
    cursor = grip.cget(:cursor)
    errors << "cursor failed" unless cursor == "sizing"

    raise "SizeGrip test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
