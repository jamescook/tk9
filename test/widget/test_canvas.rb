# frozen_string_literal: true

# Comprehensive test for Tk::Canvas widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/canvas.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestCanvasWidget < Minitest::Test
  include TkTestHelper

  def test_canvas_comprehensive
    assert_tk_app("Canvas widget comprehensive test", method(:canvas_app))
  end

  def canvas_app
    require 'tk'
    require 'tk/canvas'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Basic creation with size ---
    canvas = TkCanvas.new(root, width: 400, height: 300)
    canvas.pack(fill: "both", expand: true)
    errors << "width mismatch" unless canvas.cget(:width).to_i == 400
    errors << "height mismatch" unless canvas.cget(:height).to_i == 300

    # --- Relief and border ---
    canvas.configure(relief: "sunken", borderwidth: 2)
    errors << "relief failed" unless canvas.cget(:relief) == "sunken"
    errors << "borderwidth failed" unless canvas.cget(:borderwidth).to_i == 2

    # --- Scroll region ---
    canvas.configure(scrollregion: [0, 0, 800, 600])
    sr = canvas.cget(:scrollregion)
    errors << "scrollregion not set" if sr.nil? || sr.empty?

    # --- Confine option ---
    canvas.configure(confine: true)
    errors << "confine failed" unless canvas.cget(:confine)

    # --- Closeenough (float) ---
    canvas.configure(closeenough: 2.5)
    errors << "closeenough failed" unless canvas.cget(:closeenough) == 2.5

    # --- Scroll increments ---
    canvas.configure(xscrollincrement: 10, yscrollincrement: 10)
    errors << "xscrollincrement failed" unless canvas.cget(:xscrollincrement).to_i == 10
    errors << "yscrollincrement failed" unless canvas.cget(:yscrollincrement).to_i == 10

    # --- Selection colors ---
    canvas.configure(selectbackground: "blue", selectforeground: "white")
    errors << "selectbackground failed" if canvas.cget(:selectbackground).to_s.empty?

    # --- Insert cursor options ---
    canvas.configure(insertwidth: 3, insertofftime: 300, insertontime: 600)
    errors << "insertwidth failed" unless canvas.cget(:insertwidth).to_i == 3
    errors << "insertofftime failed" unless canvas.cget(:insertofftime) == 300
    errors << "insertontime failed" unless canvas.cget(:insertontime) == 600

    # --- Draw some items to verify canvas works ---
    # Rectangle
    rect = TkcRectangle.new(canvas, 10, 10, 100, 80,
      fill: "lightblue", outline: "navy")
    errors << "rectangle not created" unless rect.id

    # Oval
    oval = TkcOval.new(canvas, 120, 10, 200, 80,
      fill: "lightgreen", outline: "darkgreen")
    errors << "oval not created" unless oval.id

    # Line
    line = TkcLine.new(canvas, 10, 100, 200, 100,
      fill: "red", width: 2)
    errors << "line not created" unless line.id

    # Text
    text = TkcText.new(canvas, 100, 150,
      text: "Hello Canvas", fill: "black")
    errors << "text not created" unless text.id

    # Polygon
    poly = TkcPolygon.new(canvas, 250, 10, 300, 80, 200, 80,
      fill: "yellow", outline: "orange")
    errors << "polygon not created" unless poly.id

    # --- Item operations ---
    # Move an item
    canvas.move(rect, 5, 5)

    # Get bounding box
    bbox = canvas.bbox(rect)
    errors << "bbox failed" unless bbox.is_a?(Array) && bbox.size == 4

    # Find items
    all_items = canvas.find_all
    errors << "find_all failed" unless all_items.size >= 5

    # Delete an item
    line.delete
    errors << "delete failed" if canvas.find_withtag(line.id).any?

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Canvas test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
