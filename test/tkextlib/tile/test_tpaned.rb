# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TPaned widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_panedwindow.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTPanedWidget < Minitest::Test
  include TkTestHelper

  def test_tpaned_comprehensive
    assert_tk_app("TPaned widget comprehensive test", method(:tpaned_app))
  end

  def tpaned_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Horizontal paned window ---
    hpaned = Tk::Tile::TPaned.new(frame, orient: "horizontal")
    hpaned.pack(fill: "both", expand: true, pady: 10)

    errors << "orient horizontal failed" unless hpaned.cget(:orient) == "horizontal"

    # Add panes
    left_pane = Tk::Tile::TFrame.new(hpaned)
    Tk::Tile::TLabel.new(left_pane, text: "Left Pane").pack(padx: 20, pady: 20)

    right_pane = Tk::Tile::TFrame.new(hpaned)
    Tk::Tile::TLabel.new(right_pane, text: "Right Pane").pack(padx: 20, pady: 20)

    hpaned.add(left_pane, weight: 1)
    hpaned.add(right_pane, weight: 1)

    # --- Verify panes ---
    panes = hpaned.panes
    errors << "panes count failed" unless panes.size == 2

    # --- Width and height ---
    hpaned.configure(width: 400)
    errors << "width failed" unless hpaned.cget(:width).to_i == 400

    hpaned.configure(height: 200)
    errors << "height failed" unless hpaned.cget(:height).to_i == 200

    # --- Vertical paned window ---
    vpaned = Tk::Tile::TPaned.new(frame, orient: "vertical")
    vpaned.pack(fill: "both", expand: true, pady: 10)

    errors << "orient vertical failed" unless vpaned.cget(:orient) == "vertical"

    top_pane = Tk::Tile::TFrame.new(vpaned)
    Tk::Tile::TLabel.new(top_pane, text: "Top Pane").pack(padx: 20, pady: 20)

    bottom_pane = Tk::Tile::TFrame.new(vpaned)
    Tk::Tile::TLabel.new(bottom_pane, text: "Bottom Pane").pack(padx: 20, pady: 20)

    vpaned.add(top_pane)
    vpaned.add(bottom_pane)

    # --- Pane configuration ---
    hpaned.paneconfigure(left_pane, weight: 2)
    weight = hpaned.panecget(left_pane, :weight)
    errors << "paneconfigure/panecget failed" unless weight.to_i == 2

    # --- Sash position ---
    # Set sash position (index 0 is between first and second pane)
    hpaned.sashpos(0, 150)
    pos = hpaned.sashpos(0)
    errors << "sashpos failed" unless pos.to_i == 150

    # --- Insert pane at position ---
    middle_pane = Tk::Tile::TFrame.new(hpaned)
    Tk::Tile::TLabel.new(middle_pane, text: "Middle").pack(padx: 10, pady: 10)
    hpaned.insert(1, middle_pane, weight: 1)

    errors << "insert failed" unless hpaned.panes.size == 3

    # --- Forget pane ---
    hpaned.forget(middle_pane)
    errors << "forget failed" unless hpaned.panes.size == 2

    # --- Style (ttk-specific) ---
    original_style = hpaned.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Class method style ---
    style_str = Tk::Tile::TPaned.style
    errors << "class style() failed" unless style_str == 'TPaned'

    style_custom = Tk::Tile::TPaned.style('Custom')
    errors << "class style('Custom') failed" unless style_custom == 'TPaned.Custom'

    # --- Aliases ---
    errors << "PanedWindow alias missing" unless Tk::Tile::PanedWindow == Tk::Tile::TPaned
    errors << "Panedwindow alias missing" unless Tk::Tile::Panedwindow == Tk::Tile::TPaned
    errors << "Paned alias missing" unless Tk::Tile::Paned == Tk::Tile::TPaned

    # --- panecget variants ---
    weight_str = hpaned.panecget_tkstring(left_pane, :weight)
    errors << "panecget_tkstring failed" if weight_str.nil?

    weight_strict = hpaned.panecget_strict(left_pane, :weight)
    errors << "panecget_strict failed" if weight_strict.nil?

    # Aliases
    weight_alias = hpaned.pane_cget(left_pane, :weight)
    errors << "pane_cget alias failed" if weight_alias.nil?

    # --- pane_configure alias ---
    hpaned.pane_configure(left_pane, weight: 3)
    errors << "pane_configure alias failed" unless hpaned.panecget(left_pane, :weight).to_i == 3

    # --- Add multiple panes at once ---
    paned3 = Tk::Tile::TPaned.new(frame, orient: "horizontal")
    p1 = Tk::Tile::TFrame.new(paned3)
    p2 = Tk::Tile::TFrame.new(paned3)
    p3 = Tk::Tile::TFrame.new(paned3)
    paned3.add(p1, p2, p3, weight: 1)
    errors << "add multiple panes failed" unless paned3.panes.size == 3

    # --- identify (returns sash index at coordinates, or nil) ---
    # We need the widget to be mapped to test identify
    Tk.update
    _result = hpaned.identify(150, 10)
    # Result may be nil if not over a sash, that's ok

    raise "TPaned test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
