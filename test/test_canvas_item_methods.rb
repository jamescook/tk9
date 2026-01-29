# frozen_string_literal: true

# Tests for canvas item methods (move, scale, lower, raise, etc.)
# These are NOT config options - they're canvas commands that must not
# be routed through itemconfigure.

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestCanvasItemMethods < Minitest::Test
  include TkTestHelper

  def test_canvas_item_move
    assert_tk_app("canvas item move", method(:app_canvas_item_move))
  end

  def app_canvas_item_move
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 0, 0, 50, 50)

    initial = rect.coords
    rect.move(100, 100)
    moved = rect.coords

    raise "move failed: x should change" unless moved[0] == initial[0] + 100
    raise "move failed: y should change" unless moved[1] == initial[1] + 100
  end

  def test_canvas_item_scale
    assert_tk_app("canvas item scale", method(:app_canvas_item_scale))
  end

  def app_canvas_item_scale
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 0, 0, 100, 100)

    rect.scale(0, 0, 2, 2)  # scale by 2x from origin
    scaled = rect.coords

    raise "scale failed: expected 200, got #{scaled[2]}" unless scaled[2] == 200
    raise "scale failed: expected 200, got #{scaled[3]}" unless scaled[3] == 200
  end

  def test_canvas_item_lower_raise
    assert_tk_app("canvas item lower/raise", method(:app_canvas_item_lower_raise))
  end

  def app_canvas_item_lower_raise
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect1 = TkcRectangle.new(canvas, 0, 0, 50, 50, fill: 'red')
    rect2 = TkcRectangle.new(canvas, 25, 25, 75, 75, fill: 'blue')

    # rect2 is on top initially
    # lower rect2 below rect1
    rect2.lower(rect1)

    # raise rect2 back above rect1
    rect2.raise(rect1)

    # If we get here without error, the methods work
  end

  def test_canvas_item_bbox
    assert_tk_app("canvas item bbox", method(:app_canvas_item_bbox))
  end

  def app_canvas_item_bbox
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 10, 20, 110, 120)

    bbox = rect.bbox
    raise "bbox should return array" unless bbox.is_a?(Array)
    raise "bbox should have 4 elements" unless bbox.size == 4
  end

  def test_canvas_item_moveto
    assert_tk_app("canvas item moveto", method(:app_canvas_item_moveto))
  end

  def app_canvas_item_moveto
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 0, 0, 50, 50)

    rect.moveto(200, 200)
    moved = rect.coords

    # Allow 1-2 pixel tolerance due to Tk bounding box calculations
    raise "moveto failed: expected x~200, got #{moved[0]}" unless (moved[0] - 200).abs <= 2
    raise "moveto failed: expected y~200, got #{moved[1]}" unless (moved[1] - 200).abs <= 2
  end
end
