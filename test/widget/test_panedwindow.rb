# frozen_string_literal: true

# Comprehensive test for Tk::PanedWindow widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/panedwindow.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestPanedWindowWidget < Minitest::Test
  include TkTestHelper

  def test_panedwindow_comprehensive
    assert_tk_app("PanedWindow widget comprehensive test", method(:panedwindow_app))
  end

  def panedwindow_app
    require 'tk'
    require 'tk/panedwindow'
    require 'tk/frame'
    require 'tk/label'
    require 'tk/button'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Horizontal paned window ---
    h_paned = TkPanedWindow.new(root, orient: "horizontal")
    h_paned.pack(fill: "both", expand: true, padx: 10, pady: 10)

    errors << "orient failed" unless h_paned.cget(:orient) == "horizontal"

    # Add left pane
    left_frame = TkFrame.new(h_paned, width: 150, height: 200, bg: "lightblue")
    TkLabel.new(left_frame, text: "Left Pane", bg: "lightblue").pack(pady: 10)

    # Add right pane
    right_frame = TkFrame.new(h_paned, width: 200, height: 200, bg: "lightgreen")
    TkLabel.new(right_frame, text: "Right Pane", bg: "lightgreen").pack(pady: 10)

    h_paned.add(left_frame, right_frame)

    # --- Sash appearance ---
    h_paned.configure(sashwidth: 8)
    errors << "sashwidth failed" unless h_paned.cget(:sashwidth).to_i == 8

    h_paned.configure(sashpad: 2)
    errors << "sashpad failed" unless h_paned.cget(:sashpad).to_i == 2

    h_paned.configure(sashrelief: "raised")
    errors << "sashrelief failed" unless h_paned.cget(:sashrelief) == "raised"

    # --- Handle appearance ---
    h_paned.configure(showhandle: true)
    errors << "showhandle true failed" unless h_paned.cget(:showhandle)

    h_paned.configure(handlesize: 10)
    errors << "handlesize failed" unless h_paned.cget(:handlesize).to_i == 10

    h_paned.configure(handlepad: 8)
    errors << "handlepad failed" unless h_paned.cget(:handlepad).to_i == 8

    # --- Opaque resize ---
    h_paned.configure(opaqueresize: false)
    errors << "opaqueresize false failed" if h_paned.cget(:opaqueresize)

    h_paned.configure(opaqueresize: true)
    errors << "opaqueresize true failed" unless h_paned.cget(:opaqueresize)

    # --- Border ---
    h_paned.configure(borderwidth: 2)
    errors << "borderwidth failed" unless h_paned.cget(:borderwidth).to_i == 2

    # --- Vertical paned window ---
    v_paned = TkPanedWindow.new(root, orient: "vertical")
    errors << "vertical orient failed" unless v_paned.cget(:orient) == "vertical"

    # Add top and bottom panes
    top_frame = TkFrame.new(v_paned, width: 200, height: 100, bg: "lightyellow")
    bottom_frame = TkFrame.new(v_paned, width: 200, height: 100, bg: "lightpink")
    v_paned.add(top_frame, bottom_frame)

    # --- Pane operations ---
    panes = h_paned.panes
    errors << "panes count failed" unless panes.size == 2

    # --- Pane configuration ---
    h_paned.paneconfigure(left_frame, minsize: 100)
    # Note: panecget returns different types depending on option

    # --- Sash operations ---
    coords = h_paned.sash_coord(0)
    errors << "sash_coord failed" unless coords.is_a?(Array) && coords.size == 2

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "PanedWindow test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
