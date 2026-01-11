# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TScrollbar widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_scrollbar.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTScrollbarWidget < Minitest::Test
  include TkTestHelper

  def test_tscrollbar_comprehensive
    assert_tk_app("TScrollbar widget comprehensive test", method(:tscrollbar_app))
  end

  def tscrollbar_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Vertical scrollbar ---
    vscroll = Tk::Tile::TScrollbar.new(frame, orient: "vertical")
    vscroll.pack(side: "right", fill: "y")

    errors << "orient vertical failed" unless vscroll.cget(:orient) == "vertical"

    # --- Horizontal scrollbar ---
    hscroll = Tk::Tile::TScrollbar.new(frame, orient: "horizontal")
    hscroll.pack(side: "bottom", fill: "x")

    errors << "orient horizontal failed" unless hscroll.cget(:orient) == "horizontal"

    # --- Style (ttk-specific) ---
    original_style = vscroll.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Connect scrollbar to a listbox ---
    listbox = Tk::Listbox.new(frame,
      yscrollcommand: proc { |*args| vscroll.set(*args) },
      height: 10
    )
    listbox.pack(side: "left", fill: "both", expand: true)

    vscroll.configure(command: proc { |*args| listbox.yview(*args) })

    # Populate listbox to enable scrolling
    50.times { |i| listbox.insert("end", "Item #{i + 1}") }

    # Verify command is set
    cmd = vscroll.cget(:command)
    errors << "command cget failed" if cmd.nil?

    # --- XScrollbar and YScrollbar convenience classes ---
    xscroll = Tk::Tile::XScrollbar.new(frame)
    errors << "XScrollbar orient failed" unless xscroll.cget(:orient) == "horizontal"

    yscroll = Tk::Tile::YScrollbar.new(frame)
    errors << "YScrollbar orient failed" unless yscroll.cget(:orient) == "vertical"

    # --- Scrollbar methods ---
    # set(first, last) - set the scrollbar position
    vscroll.set(0.0, 0.5)  # Show first half

    # get() returns [first, last]
    first, last = vscroll.get
    errors << "set/get failed" unless first.to_f >= 0.0 && last.to_f <= 1.0

    raise "TScrollbar test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
