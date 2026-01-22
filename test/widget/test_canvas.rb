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

    # --- Confine option (DSL-declared boolean) ---
    canvas.configure(confine: true)
    errors << "confine true failed" unless canvas.cget(:confine)
    errors << "confine true not boolean" unless canvas.cget(:confine).is_a?(TrueClass)
    canvas.configure(confine: false)
    errors << "confine false failed" if canvas.cget(:confine)
    errors << "confine false not boolean" unless canvas.cget(:confine).is_a?(FalseClass)
    canvas.configure(confine: true)

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

    # ========================================
    # Item Configuration Tests (itemconfigure/itemcget)
    # ========================================

    # --- Rectangle item options ---
    rect.configure(fill: "red")
    errors << "rect itemconfigure fill failed" unless rect.cget(:fill) == "red"

    rect.configure(outline: "black")
    errors << "rect itemconfigure outline failed" unless rect.cget(:outline) == "black"

    rect.configure(width: 3)
    errors << "rect itemconfigure width failed" unless rect.cget(:width).to_i == 3

    rect.configure(state: "disabled")
    errors << "rect itemconfigure state failed" unless rect.cget(:state) == "disabled"

    rect.configure(state: "normal")

    # --- Oval item options ---
    oval.configure(fill: "orange")
    errors << "oval itemconfigure fill failed" unless oval.cget(:fill) == "orange"

    oval.configure(outline: "brown", width: 2)
    errors << "oval itemconfigure outline failed" unless oval.cget(:outline) == "brown"
    errors << "oval itemconfigure width failed" unless oval.cget(:width).to_i == 2

    # --- Text item options ---
    text.configure(fill: "blue")
    errors << "text item fill failed" unless text.cget(:fill) == "blue"

    text.configure(text: "Updated Text")
    errors << "text item text failed" unless text.cget(:text) == "Updated Text"

    text.configure(anchor: "nw")
    errors << "text item anchor failed" unless text.cget(:anchor) == "nw"

    text.configure(justify: "center")
    errors << "text item justify failed" unless text.cget(:justify) == "center"

    # --- Polygon item options ---
    poly.configure(fill: "purple")
    errors << "poly itemconfigure fill failed" unless poly.cget(:fill) == "purple"

    poly.configure(outline: "white", width: 2)
    errors << "poly itemconfigure outline failed" unless poly.cget(:outline) == "white"

    poly.configure(smooth: true)
    errors << "poly itemconfigure smooth failed" unless poly.cget(:smooth)

    # --- Create a new line and test line-specific options ---
    line2 = TkcLine.new(canvas, 10, 200, 200, 200, fill: "green", width: 1)

    line2.configure(arrow: "last")
    errors << "line arrow failed" unless line2.cget(:arrow) == "last"

    line2.configure(capstyle: "round")
    errors << "line capstyle failed" unless line2.cget(:capstyle) == "round"

    line2.configure(joinstyle: "round")
    errors << "line joinstyle failed" unless line2.cget(:joinstyle) == "round"

    line2.configure(smooth: true)
    errors << "line smooth failed" unless line2.cget(:smooth)

    # --- Canvas window item val2ruby conversion ---
    # Tests that itemcget(:window) returns a widget object, not a string path
    # This exercises __item_val2ruby_optkeys conversion
    embedded_btn = TkButton.new(canvas, text: "Embedded")
    win_item = TkcWindow.new(canvas, 250, 150, window: embedded_btn)
    retrieved_window = win_item.cget(:window)
    errors << "canvas window val2ruby should return widget" unless retrieved_window.respond_to?(:path)
    errors << "canvas window val2ruby should return same widget" unless retrieved_window.path == embedded_btn.path

    # --- Canvas tags val2ruby conversion ---
    # Tests that itemcget(:tags) returns TkcTag objects, not strings
    # This exercises __item_val2ruby_optkeys conversion
    # Note: Only explicitly created TkcTag objects get registered in the lookup table
    # String tags without corresponding TkcTag objects are returned as strings
    require 'tk/canvastag'
    my_tag = TkcTag.new(canvas)
    tagged_rect = TkcRectangle.new(canvas, 300, 100, 350, 150, tags: [my_tag])
    retrieved_tags = tagged_rect.cget(:tags)
    errors << "canvas tags val2ruby should return array" unless retrieved_tags.is_a?(Array)
    errors << "canvas tags val2ruby should have elements" if retrieved_tags.empty?
    # The registered TkcTag should be returned as a TkcTag object
    errors << "canvas tags val2ruby first tag should be TkcTag" unless retrieved_tags.first.respond_to?(:id)
    errors << "canvas tags val2ruby should return same tag" unless retrieved_tags.first.id == my_tag.id

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      raise "Canvas test failures:\n  " + errors.join("\n  ")
    end

  end

  # ---------------------------------------------------------
  # Canvas subclass with items created in initialize
  # ---------------------------------------------------------

  def test_canvas_subclass_with_items
    assert_tk_app("Canvas subclass with items", method(:canvas_subclass_app))
  end

  def canvas_subclass_app
    require 'tk'
    require 'tk/canvas'

    errors = []

    # Define a subclass that creates items in initialize
    # Use positional args to match TkCanvas's actual signature
    custom_canvas_class = Class.new(TkCanvas) do
      attr_reader :rect

      def initialize(parent, keys=nil)
        super
        # Create an item during initialization - this tests that
        # @items is properly initialized before items are created
        @rect = TkcRectangle.new(self, 10, 10, 50, 50, fill: "red")
      end
    end

    # This should work without error
    canvas = custom_canvas_class.new(root, width: 200, height: 200)
    canvas.pack

    errors << "subclass rect not created" unless canvas.rect
    errors << "subclass rect id missing" unless canvas.rect.id

    # Verify item lookup works
    found = TkcItem.id2obj(canvas, canvas.rect.id)
    errors << "subclass item lookup failed" unless found == canvas.rect

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Item/tag lookup via id2obj
  # ---------------------------------------------------------

  def test_canvas_id2obj_lookup
    assert_tk_app("Canvas id2obj lookup", method(:id2obj_lookup_app))
  end

  def id2obj_lookup_app
    require 'tk'
    require 'tk/canvas'
    require 'tk/canvastag'

    errors = []

    canvas = TkCanvas.new(root, width: 200, height: 200)
    canvas.pack

    # Create an item
    rect = TkcRectangle.new(canvas, 10, 10, 50, 50, fill: "blue")
    item_id = rect.id

    # Create a tag
    tag = TkcTag.new(canvas)
    tag_id = tag.id

    # Verify TkcItem.id2obj returns the Ruby object
    found_item = TkcItem.id2obj(canvas, item_id)
    errors << "TkcItem.id2obj should return TkcItem, got #{found_item.class}" unless found_item.kind_of?(TkcItem)
    errors << "TkcItem.id2obj should return same object" unless found_item == rect

    # Verify TkcTag.id2obj returns the Ruby object
    found_tag = TkcTag.id2obj(canvas, tag_id)
    errors << "TkcTag.id2obj should return TkcTag, got #{found_tag.class}" unless found_tag.kind_of?(TkcTag)
    errors << "TkcTag.id2obj should return same object" unless found_tag == tag

    # Unknown ID should return the id itself
    unknown = TkcItem.id2obj(canvas, 99999)
    errors << "TkcItem.id2obj should return id for unknown" unless unknown == 99999

    raise errors.join("\n") unless errors.empty?
  end
end
