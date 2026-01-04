# frozen_string_literal: true

# Comprehensive test for Tk::LabelFrame widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/labelframe.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestLabelFrameWidget < Minitest::Test
  include TkTestHelper

  def test_labelframe_comprehensive
    assert_tk_app("LabelFrame widget comprehensive test", method(:labelframe_app))
  end

  def labelframe_app
    require 'tk'
    require 'tk/labelframe'
    require 'tk/label'
    require 'tk/entry'
    require 'tk/checkbutton'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Basic labelframe with text ---
    lf1 = TkLabelFrame.new(root,
      text: "Personal Info",
      padx: 10,
      pady: 10
    )
    lf1.pack(fill: "both", expand: true, padx: 10, pady: 10)

    errors << "text failed" unless lf1.cget(:text) == "Personal Info"

    # Add some content
    TkLabel.new(lf1, text: "Name:").grid(row: 0, column: 0, sticky: "e")
    TkEntry.new(lf1, width: 20).grid(row: 0, column: 1, pady: 2)

    TkLabel.new(lf1, text: "Email:").grid(row: 1, column: 0, sticky: "e")
    TkEntry.new(lf1, width: 20).grid(row: 1, column: 1, pady: 2)

    # --- Label anchor ---
    lf2 = TkLabelFrame.new(root, text: "Options", labelanchor: "n")
    lf2.pack(fill: "x", padx: 10, pady: 5)

    errors << "labelanchor failed" unless lf2.cget(:labelanchor) == "n"

    lf2.configure(labelanchor: "nw")
    errors << "labelanchor nw failed" unless lf2.cget(:labelanchor) == "nw"

    lf2.configure(labelanchor: "ne")
    errors << "labelanchor ne failed" unless lf2.cget(:labelanchor) == "ne"

    # Add checkbuttons as content
    TkCheckbutton.new(lf2, text: "Enable feature A").pack(anchor: "w")
    TkCheckbutton.new(lf2, text: "Enable feature B").pack(anchor: "w")

    # --- Border and relief (inherited from Frame) ---
    lf1.configure(borderwidth: 3)
    errors << "borderwidth failed" unless lf1.cget(:borderwidth).to_i == 3

    lf1.configure(relief: "ridge")
    errors << "relief failed" unless lf1.cget(:relief) == "ridge"

    # --- Size ---
    lf3 = TkLabelFrame.new(root, text: "Fixed Size", width: 200, height: 100)
    lf3.pack(padx: 10, pady: 5)
    lf3.pack_propagate(false)  # Keep fixed size

    errors << "width failed" unless lf3.cget(:width).to_i == 200
    errors << "height failed" unless lf3.cget(:height).to_i == 100

    # --- Padding (inherited) ---
    lf1.configure(padx: 15, pady: 15)
    errors << "padx failed" unless lf1.cget(:padx).to_i == 15
    errors << "pady failed" unless lf1.cget(:pady).to_i == 15

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "LabelFrame test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
